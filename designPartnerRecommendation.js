import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRecommendationData from "@salesforce/apex/DesignPartnerRecommendationController.getRecommendationData";

// Opportunity 필드들
import OPPORTUNITY_NAME from "@salesforce/schema/Opportunity.Name";
import OPPORTUNITY_STAGE from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_AMOUNT from "@salesforce/schema/Opportunity.Amount";
import OPPORTUNITY_ACCOUNT_NAME from "@salesforce/schema/Opportunity.Account.Name";
import OPPORTUNITY_ACCOUNT_INDUSTRY from "@salesforce/schema/Opportunity.Account.Industry";
import OPPORTUNITY_CLOSEDATE from "@salesforce/schema/Opportunity.CloseDate";
import OPPORTUNITY_DESCRIPTION from "@salesforce/schema/Opportunity.Description";
import OPPORTUNITY_PROJECT_TYPE from "@salesforce/schema/Opportunity.ProjectType__c";
import OPPORTUNITY_SF_PRODUCT from "@salesforce/schema/Opportunity.sf_product__c";

const OPPORTUNITY_FIELDS = [
  OPPORTUNITY_NAME,
  OPPORTUNITY_STAGE,
  OPPORTUNITY_AMOUNT,
  OPPORTUNITY_ACCOUNT_NAME,
  OPPORTUNITY_ACCOUNT_INDUSTRY,
  OPPORTUNITY_CLOSEDATE,
  OPPORTUNITY_DESCRIPTION,
  OPPORTUNITY_PROJECT_TYPE,
  OPPORTUNITY_SF_PRODUCT
];

export default class DesignPartnerRecommendation extends LightningElement {
  @api recordId; // Opportunity ID
  @track isLoading = false;
  @track recommendation = "";
  @track showRecommendation = false;
  @track error;

  // Opportunity 데이터 가져오기
  @wire(getRecord, { recordId: "$recordId", fields: OPPORTUNITY_FIELDS })
  opportunity;

  get opportunityName() {
    return getFieldValue(this.opportunity.data, OPPORTUNITY_NAME);
  }

  get stageName() {
    return getFieldValue(this.opportunity.data, OPPORTUNITY_STAGE);
  }

  get accountName() {
    return getFieldValue(this.opportunity.data, OPPORTUNITY_ACCOUNT_NAME);
  }

  get projectType() {
    return getFieldValue(this.opportunity.data, OPPORTUNITY_PROJECT_TYPE);
  }

  get sfProduct() {
    return getFieldValue(this.opportunity.data, OPPORTUNITY_SF_PRODUCT);
  }

  get isVisitEstimateStage() {
    return this.stageName === "네고&최종협상";
  }

  // 추천 받기 버튼 클릭
  async handleGetRecommendation() {
    console.log("=== handleGetRecommendation 시작 ===");
    console.log("recordId:", this.recordId);

    this.isLoading = true;
    this.error = null;

    try {
      console.log("getRecommendationData 호출 시작");
      // Apex에서 데이터 조회
      const result = await getRecommendationData({
        opportunityId: this.recordId
      });
      console.log("getRecommendationData 결과:", result);
      console.log("partners 배열:", result.partners);
      console.log(
        "partners 길이:",
        result.partners ? result.partners.length : "partners is null/undefined"
      );

      // 결과 표시 로직 개선
      if (result && result.partners && result.partners.length > 0) {
        const projectType = result.opportunity?.ProjectType__c;
        const designPreference =
          result.opportunity?.Customer_Design_Preference__c;
        const sfProduct = result.opportunity?.sf_product__c;

        this.recommendation = `🎯 AI 추천 디자인 파트너사 Top 3\n`;
        this.recommendation += `📋 프로젝트 유형: ${projectType || "정보 없음"}\n`;
        this.recommendation += `🎨 선호 디자인 스타일: ${designPreference || "정보 없음"}\n`;
        this.recommendation += `🏷️ 제품: ${sfProduct || "정보 없음"}\n\n`;

        result.partners.forEach((partner, index) => {
          const isProjectTypeMatched = partner.AccountRole__c === projectType;
          const isDesignStyleMatched =
            partner.Design_Style_Specialties__c === designPreference;
          const isProductMatched = partner.PartnerSpecialty__c === sfProduct;

          let matchIcon = "•";
          let priorityText = "";
          let matchCount = 0;

          if (isProjectTypeMatched) matchCount++;
          if (isDesignStyleMatched) matchCount++;
          if (isProductMatched) matchCount++;

          if (matchCount === 3) {
            matchIcon = "�";
            priorityText = " (완벽 매칭 - 1순위)";
          } else if (matchCount === 2) {
            matchIcon = "🌟";
            priorityText = " (2개 매칭 - 2순위)";
          } else if (matchCount === 1) {
            matchIcon = "⭐";
            priorityText = " (1개 매칭 - 3순위)";
          } else {
            matchIcon = "•";
            priorityText = " (4순위)";
          }

          this.recommendation += `${matchIcon} ${index + 1}. ${partner.Name}${priorityText}\n`;

          if (partner.AccountRole__c) {
            this.recommendation += `   ➤ 전문분야: ${partner.AccountRole__c}`;
            if (isProjectTypeMatched) this.recommendation += " ✓";
            this.recommendation += `\n`;
          }
          if (partner.Design_Style_Specialties__c) {
            this.recommendation += `   ➤ 디자인 스타일: ${partner.Design_Style_Specialties__c}`;
            if (isDesignStyleMatched) this.recommendation += " ✓";
            this.recommendation += `\n`;
          }
          if (partner.PartnerSpecialty__c) {
            this.recommendation += `   ➤ 담당 브랜드: ${partner.PartnerSpecialty__c}`;
            if (isProductMatched) this.recommendation += " ✓";
            this.recommendation += `\n`;
          }
          if (partner.PartnerRating__c) {
            this.recommendation += `   ➤ 평점: ${partner.PartnerRating__c}점\n`;
          }
          this.recommendation += `\n`;
        });
      } else {
        this.recommendation = `😔 조건에 맞는 디자인 파트너사를 찾을 수 없습니다.\n\n`;
        this.recommendation += `검색 조건:\n`;
        this.recommendation += `• Opportunity ID: ${this.recordId}\n`;
        this.recommendation += `• 파트너 역할: 시공업체, 리모델링, 인테리어\n`;
      }

      this.showRecommendation = true;

      this.showToast("성공", "시공사 추천이 완료되었습니다.", "success");
    } catch (error) {
      console.error("Error:", error);
      this.error = error.body?.message || error.message;
      this.recommendation = `오류 발생: ${this.error}`;
      this.showRecommendation = true;
      this.showToast(
        "오류",
        "추천 과정에서 오류가 발생했습니다: " + this.error,
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }
}
