public with sharing class DesignPartnerRecommendationController {
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getRecommendationData(Id opportunityId) {
    System.debug('=== getRecommendationData 호출 ===');

    try {
      // Opportunity 정보 조회
      Opportunity opp = [
        SELECT
          Id,
          Name,
          Customer_Design_Preference__c,
          Budget__c,
          ProjectType__c,
          sf_product__c
        FROM Opportunity
        WHERE Id = :opportunityId
        LIMIT 1
      ];

      System.debug('프로젝트 유형: ' + opp.ProjectType__c);
      System.debug('디자인 선호: ' + opp.Customer_Design_Preference__c);
      System.debug('제품: ' + opp.sf_product__c);

      // 파트너사 조회 (Top 3만)
      List<Account> partners = [
        SELECT
          Id,
          Name,
          Design_Style_Specialties__c,
          AccountRole__c,
          PartnerSpecialty__c,
          PartnerRating__c
        FROM Account
        WHERE AccountRole__c IN ('시공업체', '리모델링', '인테리어')
        ORDER BY PartnerRating__c DESC NULLS LAST, Name
        LIMIT 3
      ];

      System.debug('파트너 조회 결과: ' + partners.size() + '개');

      // AI 추천 생성
      String aiRecommendation = generateAIRecommendation(opp, partners);

      Map<String, Object> result = new Map<String, Object>();
      result.put('opportunity', opp);
      result.put('partners', partners);
      result.put('aiRecommendation', aiRecommendation);
      return result;
    } catch (Exception e) {
      throw new AuraHandledException('조회 실패: ' + e.getMessage());
    }
  }

  // AI 추천 생성 (핵심 로직만)
  private static String generateAIRecommendation(
    Opportunity opp,
    List<Account> partners
  ) {
    String result = '🤖 AI 추천 결과\n\n';

    // 프로젝트 정보
    result += '📋 프로젝트: ' + opp.Name + '\n';
    result += '🏗️ 유형: ' + (opp.ProjectType__c ?? '미정') + '\n';
    result +=
      '🎨 스타일: ' +
      (opp.Customer_Design_Preference__c ?? '미정') +
      '\n';
    result += '🏷️ 제품: ' + (opp.sf_product__c ?? '미정') + '\n\n';

    // 파트너 점수 계산 및 추천
    List<PartnerScore> scores = new List<PartnerScore>();
    for (Account partner : partners) {
      Integer score = calculateScore(opp, partner);
      scores.add(new PartnerScore(partner, score));
    }
    scores.sort();

    result += '🎯 추천 파트너 Top 3\n\n';
    for (Integer i = 0; i < scores.size(); i++) {
      PartnerScore ps = scores[i];
      String icon = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';

      result += icon + ' ' + (i + 1) + '순위: ' + ps.partner.Name + '\n';
      result += '📊 점수: ' + ps.score + '/100점\n';
      result += '💡 이유: ' + getMatchReason(opp, ps.partner) + '\n';
      result += '⭐ 전문분야: ' + (ps.partner.AccountRole__c ?? '종합') + '\n';
      result +=
        '🎨 디자인: ' +
        (ps.partner.Design_Style_Specialties__c ?? '다양') +
        '\n\n';
    }

    return result;
  }

  // 간단한 점수 계산
  private static Integer calculateScore(Opportunity opp, Account partner) {
    Integer score = 50; // 기본 점수

    // 프로젝트 타입 매칭 (25점)
    if (partner.AccountRole__c == opp.ProjectType__c) {
      score += 25;
    } else if (isRelated(partner.AccountRole__c, opp.ProjectType__c)) {
      score += 15;
    }

    // 디자인 스타일 매칭 (15점)
    if (
      partner.Design_Style_Specialties__c == opp.Customer_Design_Preference__c
    ) {
      score += 15;
    }

    // 제품 매칭 (10점)
    if (partner.PartnerSpecialty__c == opp.sf_product__c) {
      score += 10;
    }

    // 평점 보너스 (최대 10점)
    if (partner.PartnerRating__c != null) {
      score += Integer.valueOf(partner.PartnerRating__c * 2);
    }

    return Math.min(score, 100);
  }

  // 유사 분야 판별
  private static Boolean isRelated(String role1, String role2) {
    Set<String> related = new Set<String>{ '시공업체', '리모델링', '인테리어' };
    return related.contains(role1) && related.contains(role2);
  }

  // 매칭 이유 생성
  private static String getMatchReason(Opportunity opp, Account partner) {
    List<String> reasons = new List<String>();

    if (partner.AccountRole__c == opp.ProjectType__c) {
      reasons.add('프로젝트 유형 완벽 매칭');
    }
    if (
      partner.Design_Style_Specialties__c == opp.Customer_Design_Preference__c
    ) {
      reasons.add('디자인 스타일 전문');
    }
    if (partner.PartnerSpecialty__c == opp.sf_product__c) {
      reasons.add('제품 전문 경험');
    }
    if (partner.PartnerRating__c != null && partner.PartnerRating__c >= 4.0) {
      reasons.add('높은 고객 만족도');
    }

    return reasons.isEmpty()
      ? '종합적 서비스 역량'
      : String.join(reasons, ', ');
  }

  // 점수 정렬용 내부 클래스
  private class PartnerScore implements Comparable {
    public Account partner;
    public Integer score;

    public PartnerScore(Account partner, Integer score) {
      this.partner = partner;
      this.score = score;
    }

    public Integer compareTo(Object other) {
      PartnerScore otherScore = (PartnerScore) other;
      return otherScore.score - this.score; // 내림차순
    }
  }
}
