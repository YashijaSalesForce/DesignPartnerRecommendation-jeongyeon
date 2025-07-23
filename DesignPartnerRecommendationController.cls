public with sharing class DesignPartnerRecommendationController {
  @AuraEnabled(cacheable=true)
  public static String simpleTest() {
    System.debug('=== simpleTest 호출됨 ===');
    return 'Test 성공';
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getRecommendationData(Id opportunityId) {
    System.debug('=== getRecommendationData 메소드 호출됨 ===');
    System.debug('opportunityId: ' + opportunityId);

    try {
      // Opportunity 정보 조회 - 필요한 필드만
      Opportunity opp = [
        SELECT
          Id,
          Name,
          Customer_Design_Preference__c,
          Budget__c,
          ProjectType__c,
          RecommendationDate__c,
          sf_product__c
        FROM Opportunity
        WHERE Id = :opportunityId
        LIMIT 1
      ];

      System.debug('Opportunity ProjectType__c: ' + opp.ProjectType__c);
      System.debug(
        'Customer Design Preference: ' + opp.Customer_Design_Preference__c
      );
      System.debug('SF Product: ' + opp.sf_product__c);

      // 디자인 파트너사 목록 조회 - 3가지 조건 매칭 우선순위 적용 (ProjectType, Design Style, Product)
      // 1순위: 3개 조건 모두 매칭
      List<Account> perfectMatchPartners = [
        SELECT
          Id,
          Name,
          Design_Style_Specialties__c,
          AccountRole__c,
          PartnerSpecialty__c,
          PartnerRating__c
        FROM Account
        WHERE
          AccountRole__c = :opp.ProjectType__c
          AND Design_Style_Specialties__c = :opp.Customer_Design_Preference__c
          AND PartnerSpecialty__c = :opp.sf_product__c
        ORDER BY PartnerRating__c DESC NULLS LAST, Name
        LIMIT 3
      ];

      // 2순위: 2개 조건 매칭 (ProjectType + Design Style)
      List<Account> twoMatchPartners = new List<Account>();
      if (perfectMatchPartners.size() < 3) {
        Integer remainingLimit = 3 - perfectMatchPartners.size();
        twoMatchPartners = [
          SELECT
            Id,
            Name,
            Design_Style_Specialties__c,
            AccountRole__c,
            PartnerSpecialty__c,
            PartnerRating__c
          FROM Account
          WHERE
            AccountRole__c = :opp.ProjectType__c
            AND Design_Style_Specialties__c = :opp.Customer_Design_Preference__c
            AND (PartnerSpecialty__c != :opp.sf_product__c
            OR PartnerSpecialty__c = NULL)
          ORDER BY PartnerRating__c DESC NULLS LAST, Name
          LIMIT :remainingLimit
        ];
      }

      // 3순위: 1개 조건만 매칭되는 파트너 (ProjectType 우선)
      List<Account> oneMatchPartners = new List<Account>();
      if (perfectMatchPartners.size() + twoMatchPartners.size() < 3) {
        Integer remainingLimit =
          3 -
          perfectMatchPartners.size() -
          twoMatchPartners.size();
        oneMatchPartners = [
          SELECT
            Id,
            Name,
            Design_Style_Specialties__c,
            AccountRole__c,
            PartnerSpecialty__c,
            PartnerRating__c
          FROM Account
          WHERE
            AccountRole__c = :opp.ProjectType__c
            AND (Design_Style_Specialties__c != :opp.Customer_Design_Preference__c
            OR Design_Style_Specialties__c = NULL)
            AND (PartnerSpecialty__c != :opp.sf_product__c
            OR PartnerSpecialty__c = NULL)
          ORDER BY PartnerRating__c DESC NULLS LAST, Name
          LIMIT :remainingLimit
        ];
      }

      // 4순위: 일반 파트너들
      List<Account> otherPartners = new List<Account>();
      if (
        perfectMatchPartners.size() + twoMatchPartners.size() +
        oneMatchPartners.size() < 3
      ) {
        Integer remainingLimit =
          3 -
          perfectMatchPartners.size() -
          twoMatchPartners.size() -
          oneMatchPartners.size();
        otherPartners = [
          SELECT
            Id,
            Name,
            Design_Style_Specialties__c,
            AccountRole__c,
            PartnerSpecialty__c,
            PartnerRating__c
          FROM Account
          WHERE
            AccountRole__c IN ('시공업체', '리모델링', '인테리어')
            AND AccountRole__c != :opp.ProjectType__c
            AND (Design_Style_Specialties__c != :opp.Customer_Design_Preference__c
            OR Design_Style_Specialties__c = NULL)
            AND (PartnerSpecialty__c != :opp.sf_product__c
            OR PartnerSpecialty__c = NULL)
          ORDER BY PartnerRating__c DESC NULLS LAST, Name
          LIMIT :remainingLimit
        ];
      }

      // 최종 파트너 목록 생성 (우선순위대로)
      List<Account> partners = new List<Account>();
      partners.addAll(perfectMatchPartners);
      partners.addAll(twoMatchPartners);
      partners.addAll(oneMatchPartners);
      partners.addAll(otherPartners);

      System.debug('디자인 파트너 조회 결과: ' + partners.size() + '개');
      System.debug(
        '1순위(Perfect Match): ' + perfectMatchPartners.size() + '개'
      );
      System.debug('2순위(Two Match): ' + twoMatchPartners.size() + '개');
      System.debug('3순위(One Match): ' + oneMatchPartners.size() + '개');
      System.debug('4순위(Other Partners): ' + otherPartners.size() + '개');

      // 파트너 정보 로깅 및 매칭 여부 확인
      for (Integer i = 0; i < partners.size(); i++) {
        Account partner = partners[i];
        Boolean isProjectTypeMatched =
          partner.AccountRole__c == opp.ProjectType__c;
        Boolean isDesignStyleMatched =
          partner.Design_Style_Specialties__c ==
          opp.Customer_Design_Preference__c;
        Boolean isPartnerSpecialtyMatched =
          partner.PartnerSpecialty__c == opp.sf_product__c;

        // 매칭된 조건 개수 계산
        Integer matchCount = 0;
        if (isProjectTypeMatched)
          matchCount++;
        if (isDesignStyleMatched)
          matchCount++;
        if (isPartnerSpecialtyMatched)
          matchCount++;

        String matchType = '';
        if (matchCount == 3) {
          matchType = '1순위(3/3 완벽매칭)';
        } else if (matchCount == 2) {
          matchType = '2순위(2/3 매칭)';
        } else if (matchCount == 1) {
          matchType = '3순위(1/3 매칭)';
        } else {
          matchType = '4순위(일반)';
        }

        System.debug(
          '파트너 정보 [' +
            (i + 1) +
            '] - 이름: ' +
            partner.Name +
            ', 역할: ' +
            partner.AccountRole__c +
            ', 평점: ' +
            partner.PartnerRating__c +
            ', 전문분야: ' +
            partner.PartnerSpecialty__c +
            ', 디자인스타일: ' +
            partner.Design_Style_Specialties__c +
            ', 매칭타입: ' +
            matchType +
            ', 매칭개수: ' +
            matchCount +
            '/3'
        );
      }

      // AI 추천 생성 (Prompt Builder 활용)
      String aiRecommendation = generateAIRecommendation(opp, partners);

      Map<String, Object> result = new Map<String, Object>();
      result.put('opportunity', opp);
      result.put('partners', partners);
      result.put('aiRecommendation', aiRecommendation);
      return result;
    } catch (Exception e) {
      throw new AuraHandledException('데이터 조회 실패: ' + e.getMessage());
    }
  }

  // AI 추천 생성 메소드 (Prompt Builder 활용)
  private static String generateAIRecommendation(
    Opportunity opp,
    List<Account> partners
  ) {
    try {
      // 파트너 리스트를 문자열로 변환
      String partnerListStr = formatPartnersForPrompt(partners);

      // Prompt Builder 호출을 위한 입력값 설정
      Map<String, Object> inputs = new Map<String, Object>();
      inputs.put('OpportunityName', opp.Name);
      inputs.put(
        'ProjectType',
        opp.ProjectType__c != null ? opp.ProjectType__c : '미정'
      );
      inputs.put(
        'DesignPreference',
        opp.Customer_Design_Preference__c != null
          ? opp.Customer_Design_Preference__c
          : '미정'
      );
      inputs.put(
        'ProductType',
        opp.sf_product__c != null ? opp.sf_product__c : '미정'
      );
      inputs.put(
        'Budget',
        opp.Budget__c != null ? String.valueOf(opp.Budget__c) + '원' : '미정'
      );
      inputs.put('PartnerList', partnerListStr);

      System.debug('AI 프롬프트 입력값: ' + inputs);

      // 실제 환경에서는 아래 코드로 Prompt Builder 호출
      /*
      ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput = 
          new ConnectApi.EinsteinPromptTemplateGenerationsInput();
      promptInput.inputParams = inputs;
      
      ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response = 
          ConnectApi.EinsteinAI.generatePromptTemplate('YOUR_PROMPT_TEMPLATE_ID', promptInput);
      
      return response.generation.text;
      */

      // 개발/테스트 환경에서는 시뮬레이션 사용
      return generateAdvancedRecommendation(opp, partners);
    } catch (Exception e) {
      System.debug('AI 추천 생성 오류: ' + e.getMessage());
      // AI 호출 실패 시 기본 추천 로직 사용
      return generateBasicRecommendation(opp, partners);
    }
  }

  // 파트너 정보를 프롬프트용 문자열로 변환
  private static String formatPartnersForPrompt(List<Account> partners) {
    String result = '';
    for (Integer i = 0; i < partners.size(); i++) {
      Account partner = partners[i];
      result += (i + 1) + '. **' + partner.Name + '**\n';
      result +=
        '   - 전문분야: ' +
        (partner.AccountRole__c != null ? partner.AccountRole__c : '미분류') +
        '\n';
      result +=
        '   - 디자인 스타일: ' +
        (partner.Design_Style_Specialties__c != null
          ? partner.Design_Style_Specialties__c
          : '다양') +
        '\n';
      result +=
        '   - 특장점: ' +
        (partner.PartnerSpecialty__c != null
          ? partner.PartnerSpecialty__c
          : '종합 서비스') +
        '\n';
      result +=
        '   - 평점: ' +
        (partner.PartnerRating__c != null
          ? String.valueOf(partner.PartnerRating__c) + '점'
          : '평가 중') +
        '\n\n';
    }
    return result;
  }

  // 고급 AI 시뮬레이션 추천 (Prompt Builder 스타일)
  private static String generateAdvancedRecommendation(
    Opportunity opp,
    List<Account> partners
  ) {
    String result = '🤖 AI 추천 분석 결과\n\n';

    // 매칭 점수 계산 및 정렬
    List<PartnerMatch> matches = new List<PartnerMatch>();
    for (Account partner : partners) {
      Integer score = calculateAdvancedMatchScore(opp, partner);
      String reason = generateDetailedReason(opp, partner, score);
      matches.add(new PartnerMatch(partner, score, reason));
    }
    matches.sort();

    // 프로젝트 분석
    result += '📊 **프로젝트 분석**\n';
    result += '- 프로젝트: ' + opp.Name + '\n';
    result +=
      '- 유형: ' +
      (opp.ProjectType__c != null ? opp.ProjectType__c : '미정') +
      '\n';
    result +=
      '- 스타일: ' +
      (opp.Customer_Design_Preference__c != null
        ? opp.Customer_Design_Preference__c
        : '미정') +
      '\n';
    result +=
      '- 제품: ' +
      (opp.sf_product__c != null ? opp.sf_product__c : '미정') +
      '\n\n';

    // Top 3 추천
    result += '🎯 **추천 파트너 (상위 3곳)**\n\n';
    for (Integer i = 0; i < Math.min(3, matches.size()); i++) {
      PartnerMatch match = matches[i];
      Account partner = match.partner;

      String icon = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';
      String priority = i == 0 ? '최우선 추천' : i == 1 ? '강력 추천' : '추천';

      result +=
        icon +
        ' **' +
        (i + 1) +
        '순위: ' +
        partner.Name +
        '** (' +
        priority +
        ')\n';
      result += '📊 매칭점수: ' + match.score + '/100점\n';
      result += '💡 추천이유: ' + match.reason + '\n';
      result += '⭐ 특징: ' + getPartnerStrengths(partner) + '\n\n';
    }

    // 최종 조언
    result += '💼 **선택 가이드**\n';
    result += generateSelectionGuide(opp, matches);

    return result;
  }

  // AI 호출 실패 시 사용할 기본 추천 로직
  private static String generateBasicRecommendation(
    Opportunity opp,
    List<Account> partners
  ) {
    String result = '🤖 기본 추천 시스템\n\n';

    for (Integer i = 0; i < Math.min(3, partners.size()); i++) {
      Account partner = partners[i];
      String icon = i == 0 ? '🥇' : i == 1 ? '🥈' : '🥉';

      result += icon + ' ' + (i + 1) + '순위: ' + partner.Name + '\n';
      result +=
        '📊 평점: ' +
        (partner.PartnerRating__c != null
          ? String.valueOf(partner.PartnerRating__c) + '점'
          : '평가 중') +
        '\n';
      result += '💡 추천 이유: ';

      // 간단한 매칭 로직
      if (partner.AccountRole__c == opp.ProjectType__c) {
        result += '프로젝트 유형에 특화된 전문 업체';
      } else {
        result += '종합적인 서비스 역량을 갖춘 업체';
      }
      result += '\n\n';
    }

    return result;
  }

  // 고급 매칭 점수 계산 (개선된 버전)
  private static Integer calculateAdvancedMatchScore(
    Opportunity opp,
    Account partner
  ) {
    Integer score = 0;

    // 기본 점수 (모든 파트너에게 20점 지급)
    score += 20;

    // 1. 프로젝트 타입 매칭 (30점)
    if (partner.AccountRole__c == opp.ProjectType__c) {
      score += 30; // 완벽 매칭
    } else if (partner.AccountRole__c != null && opp.ProjectType__c != null) {
      // 유사 분야 보너스 (20점)
      if (isRelatedField(partner.AccountRole__c, opp.ProjectType__c)) {
        score += 20;
      } else {
        // 다른 디자인 분야라도 기본 점수 (10점)
        score += 10;
      }
    }

    // 2. 디자인 스타일 매칭 (25점)
    if (
      partner.Design_Style_Specialties__c == opp.Customer_Design_Preference__c
    ) {
      score += 25;
    } else if (partner.Design_Style_Specialties__c != null) {
      // 다른 스타일이라도 전문성 인정 (10점)
      score += 10;
    }

    // 3. 제품 전문성 매칭 (15점)
    if (partner.PartnerSpecialty__c == opp.sf_product__c) {
      score += 15;
    } else if (partner.PartnerSpecialty__c != null) {
      // 다른 제품 전문성이라도 기본 점수 (7점)
      score += 7;
    }

    // 4. 평점 보너스 (최대 10점)
    if (partner.PartnerRating__c != null) {
      score += Integer.valueOf(partner.PartnerRating__c * 2); // 5점 만점을 10점으로 변환
    } else {
      // 평점이 없어도 기본 점수 (5점)
      score += 5;
    }

    return Math.min(score, 100); // 최대 100점
  }
  // 유사 분야 판별
  private static Boolean isRelatedField(
    String partnerRole,
    String projectType
  ) {
    Set<String> constructionFields = new Set<String>{
      '시공업체',
      '건설업체',
      '리모델링'
    };
    Set<String> designFields = new Set<String>{ '인테리어', '디자인', '시공' };

    return (constructionFields.contains(partnerRole) &&
      constructionFields.contains(projectType)) ||
      (designFields.contains(partnerRole) &&
      designFields.contains(projectType));
  }

  // 상세 추천 이유 생성
  private static String generateDetailedReason(
    Opportunity opp,
    Account partner,
    Integer score
  ) {
    List<String> reasons = new List<String>();

    if (partner.AccountRole__c == opp.ProjectType__c) {
      reasons.add('프로젝트 유형(' + opp.ProjectType__c + ')에 완벽 매칭');
    } else if (isRelatedField(partner.AccountRole__c, opp.ProjectType__c)) {
      reasons.add('관련 분야 전문성 보유');
    }

    if (
      partner.Design_Style_Specialties__c == opp.Customer_Design_Preference__c
    ) {
      reasons.add(
        '선호 디자인(' + opp.Customer_Design_Preference__c + ') 전문가'
      );
    }

    if (partner.PartnerSpecialty__c == opp.sf_product__c) {
      reasons.add('요구 제품(' + opp.sf_product__c + ') 전문 경험');
    }

    if (partner.PartnerRating__c != null && partner.PartnerRating__c >= 4.0) {
      reasons.add('검증된 고객 만족도(' + partner.PartnerRating__c + '점)');
    }

    if (reasons.isEmpty()) {
      return '종합적인 서비스 역량과 안정적인 사업 운영';
    }

    return String.join(reasons, ', ');
  }

  // 파트너 강점 분석
  private static String getPartnerStrengths(Account partner) {
    List<String> strengths = new List<String>();

    if (partner.PartnerRating__c != null && partner.PartnerRating__c >= 4.5) {
      strengths.add('프리미엄 서비스 품질');
    }

    if (partner.AccountRole__c == '시공업체') {
      strengths.add('전문 시공 기술력');
    } else if (partner.AccountRole__c == '인테리어') {
      strengths.add('창의적 디자인 역량');
    } else if (partner.AccountRole__c == '리모델링') {
      strengths.add('기존 공간 최적화 노하우');
    }

    if (partner.Design_Style_Specialties__c != null) {
      strengths.add(partner.Design_Style_Specialties__c + ' 스타일 전문성');
    }

    return strengths.isEmpty()
      ? '다년간의 업계 경험'
      : String.join(strengths, ', ');
  }

  // 선택 가이드 생성
  private static String generateSelectionGuide(
    Opportunity opp,
    List<PartnerMatch> matches
  ) {
    String guide = '';

    if (matches.size() > 0 && matches[0].score >= 80) {
      guide += '1순위 파트너는 프로젝트 요구사항과 높은 일치도를 보이므로 우선 검토를 권장합니다. ';
    }

    if (opp.Budget__c != null) {
      guide += '예산 범위 내에서 견적을 비교하시고, ';
    }

    guide += '각 파트너의 포트폴리오와 과거 프로젝트 사례를 확인하여 최종 결정하시기 바랍니다.';

    return guide;
  }

  // 매칭 결과를 담는 내부 클래스
  private class PartnerMatch implements Comparable {
    public Account partner;
    public Integer score;
    public String reason;

    public PartnerMatch(Account partner, Integer score, String reason) {
      this.partner = partner;
      this.score = score;
      this.reason = reason;
    }

    public Integer compareTo(Object other) {
      PartnerMatch otherMatch = (PartnerMatch) other;
      return otherMatch.score - this.score; // 내림차순 정렬
    }
  }
}
