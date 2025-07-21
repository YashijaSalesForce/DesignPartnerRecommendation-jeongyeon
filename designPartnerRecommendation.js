import { LightningElement, api, track, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
// 이 줄 제거: import getDesignPartners from '@salesforce/apex/DesignPartnerRecommendationController.getDesignPartners';
import getPromptRecommendation from "@salesforce/apex/DesignPartnerRecommendationController.getRecommendation";

// Opportunity 필드들
import OPPORTUNITY_NAME from "@salesforce/schema/Opportunity.Name";
import OPPORTUNITY_STAGE from "@salesforce/schema/Opportunity.StageName";
import OPPORTUNITY_AMOUNT from "@salesforce/schema/Opportunity.Amount";
import OPPORTUNITY_ACCOUNT_NAME from "@salesforce/schema/Opportunity.Account.Name";
import OPPORTUNITY_ACCOUNT_INDUSTRY from "@salesforce/schema/Opportunity.Account.Industry";
import OPPORTUNITY_CLOSEDATE from "@salesforce/schema/Opportunity.CloseDate";
import OPPORTUNITY_DESCRIPTION from "@salesforce/schema/Opportunity.Description";
import OPPORTUNITY_PROJECT_TYPE from "@salesforce/schema/Opportunity.ProjectType__c";

const OPPORTUNITY_FIELDS = [
  OPPORTUNITY_NAME,
  OPPORTUNITY_STAGE,
  OPPORTUNITY_AMOUNT,
  OPPORTUNITY_ACCOUNT_NAME,
  OPPORTUNITY_ACCOUNT_INDUSTRY,
  OPPORTUNITY_CLOSEDATE,
  OPPORTUNITY_DESCRIPTION,
  OPPORTUNITY_PROJECT_TYPE
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

  get isVisitEstimateStage() {
    return this.stageName === "네고&최종협상";
  }

  // 추천 받기 버튼 클릭
  async handleGetRecommendation() {
    this.isLoading = true;
    this.error = null;

    try {
      // Apex에서 파트너사 조회와 추천을 한번에 처리
      const promptInput = {
        opportunityId: this.recordId,
        opportunityName: this.opportunityName,
        accountName: this.accountName,
        stageName: this.stageName,
        projectType: this.projectType
      };

      this.recommendation = await getPromptRecommendation({
        inputData: JSON.stringify(promptInput)
      });

      this.showRecommendation = true;

      this.showToast(
        "성공",
        "디자인 파트너사 추천이 완료되었습니다.",
        "success"
      );
    } catch (error) {
      this.error = error.body?.message || error.message;
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
