public with sharing class DesignPartnerRecommendationController {
  @AuraEnabled
  public static String getRecommendation(String inputData) {
    try {
      Map<String, Object> input = (Map<String, Object>) JSON.deserializeUntyped(
        inputData
      );

      // Opportunity 정보 조회
      String opportunityId = (String) input.get('opportunityId');
      Opportunity opp = [
        SELECT
          Id,
          Name,
          StageName,
          Amount,
          CloseDate,
          Description,
          ProjectType__c,
          sf_product__c,
          Account.Name,
          Account.Industry,
          Account.BillingCity,
          Account.BillingState
        FROM Opportunity
        WHERE Id = :opportunityId
      ];

      // 디자인 파트너사 목록 조회
      List<Account> partners = [
        SELECT
          Id,
          Name,
          AccountRole__c,
          ABillingCity__c,
          BillingState,
          Industry,
          Description,
          PartnerSpecialty__c,
          PartnerRating__c
        FROM Account
        WHERE
          IsPartner__c = '파트너고객'
          AND AccountRole__c IN ('인테리어', '시공업체')
        ORDER BY PartnerRating__c DESC NULLS LAST, ABillingCity__c
      ];

      System.debug('파트너사 조회 결과: ' + partners.size() + '개');

      String recommendation = '';

      // 실제 AI 로직 (Prompt Builder 스타일)
      recommendation = generateAIRecommendation(opp, partners);

      // 추천 생성 일시 업데이트
      opp.RecommendationDate__c = System.now();
      update opp;

      return recommendation;
    } catch (Exception e) {
      throw new AuraHandledException(
        '추천 생성 중 오류 발생: ' + e.getMessage()
      );
    }
  }

  // AI 스타일 추천 로직 (Prompt Builder 결과와 유사하게)
  private static String generateAIRecommendation(
    Opportunity opp,
    List<Account> partners
  ) {
    if (partners.isEmpty()) {
      return '현재 이용 가능한 디자인 파트너사가 없습니다.';
    }

    // 최적 파트너사 선정 로직
    Account bestPartner = findBestPartner(opp, partners);

    // AI 스타일 응답 생성
    String response = '🏢 **추천 파트너사**: ' + bestPartner.Name;

    if (bestPartner.PartnerRating__c != null) {
      response += ' (평점: ' + bestPartner.PartnerRating__c + '/5)';
    }

    response += '\n\n📋 **추천 이유**:\n';
    response += generateRecommendationReasons(opp, bestPartner);

    response += '\n\n📅 **예상 일정**:\n';
    response += '- 견적서 제출: 3-5일\n';
    response += '- 방문 견적: 1주일 내\n';

    response +=
      '\n\n💡 **다음 단계**: ' +
      bestPartner.Name +
      '에 연락하여 상세 미팅을 진행하시기 바랍니다.';

    return response;
  }

  // 최적 파트너사 선정
  private static Account findBestPartner(
    Opportunity opp,
    List<Account> partners
  ) {
    Account bestPartner = partners[0]; // 기본: 평점 높은 순
    Integer maxScore = 0;

    for (Account partner : partners) {
      Integer score = calculatePartnerScore(opp, partner);
      if (score > maxScore) {
        maxScore = score;
        bestPartner = partner;
      }
    }

    return bestPartner;
  }

  // 파트너사 점수 계산
  private static Integer calculatePartnerScore(
    Opportunity opp,
    Account partner
  ) {
    Integer score = 0;

    // 평점 점수 (0-50점)
    if (partner.PartnerRating__c != null) {
      score += Integer.valueOf(partner.PartnerRating__c * 10);
    }

    // 전문분야 매칭 (0-30점)
    if (opp.ProjectType__c != null && partner.PartnerSpecialty__c != null) {
      if (partner.PartnerSpecialty__c.contains(opp.ProjectType__c)) {
        score += 30;
      }
    }

    // 지역 점수 (0-20점) - 용인시 우선
    if (partner.ABillingCity__c != null) {
      if (partner.ABillingCity__c.equals('용인시')) {
        score += 20;
      } else if (partner.ABillingCity__c.contains('시')) {
        score += 10;
      }
    }

    return score;
  }

  // 추천 이유 생성
  private static String generateRecommendationReasons(
    Opportunity opp,
    Account partner
  ) {
    List<String> reasons = new List<String>();

    // 전문분야 매칭
    if (
      opp.ProjectType__c != null &&
      partner.PartnerSpecialty__c != null &&
      partner.PartnerSpecialty__c.contains(opp.ProjectType__c)
    ) {
      reasons.add(opp.ProjectType__c + ' 프로젝트에 특화된 전문 경험 보유');
    } else {
      reasons.add('다양한 인테리어 프로젝트 경험으로 고품질 서비스 제공');
    }

    // 평점 기반
    if (partner.PartnerRating__c != null && partner.PartnerRating__c >= 4.0) {
      reasons.add(
        '높은 고객 만족도와 검증된 시공 실력 보유 (평점 ' +
          partner.PartnerRating__c +
          '/5)'
      );
    } else {
      reasons.add('안정적인 시공 품질과 고객 서비스 제공');
    }

    // 지역적 접근성
    if (partner.ABillingCity__c != null) {
      reasons.add(
        '지역적 접근성이 우수함 (' + partner.ABillingCity__c + ' 소재)'
      );
    } else {
      reasons.add('경기도 내 우수한 접근성으로 신속한 대응 가능');
    }

    String result = '';
    for (Integer i = 0; i < reasons.size(); i++) {
      result += (i + 1) + '. ' + reasons[i] + '\n';
    }

    return result.removeEnd('\n');
  }
}
