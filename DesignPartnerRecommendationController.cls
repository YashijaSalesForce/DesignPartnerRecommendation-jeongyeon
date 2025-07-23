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

      Map<String, Object> result = new Map<String, Object>();
      result.put('opportunity', opp);
      result.put('partners', partners);
      return result;
    } catch (Exception e) {
      throw new AuraHandledException('데이터 조회 실패: ' + e.getMessage());
    }
  }
}
