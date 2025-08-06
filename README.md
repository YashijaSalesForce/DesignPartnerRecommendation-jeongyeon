# 🤝 시공업체 추천 시스템

<div align="center">

[![Salesforce](https://img.shields.io/badge/Salesforce-00A1E0?style=for-the-badge&logo=salesforce&logoColor=white)](https://salesforce.com)
[![LWC](https://img.shields.io/badge/Lightning_Web_Components-FF6B35?style=for-the-badge&logo=lightning&logoColor=white)](https://lwc.dev/)
[![Apex](https://img.shields.io/badge/Apex-1798c1?style=for-the-badge&logo=salesforce&logoColor=white)](https://developer.salesforce.com)

**데이터 기반 의사결정으로 최적의 시공업체를 찾아드립니다**  
*Salesforce Opportunity와 연계된 지능형 파트너 매칭 시스템*

</div>

---

## 🎯 프로젝트 개요

**경험과 인맥에 의존하던 파트너 선정**을 **객관적 데이터 기반 추천**으로 혁신합니다.  
Salesforce Opportunity 레코드의 정보를 실시간으로 분석하여 프로젝트에 최적화된 시공업체를 추천합니다.

### 💡 핵심 가치

<div align="center">

| 기존 방식 | → | 새로운 방식 |
|:---:|:---:|:---:|
| 🤔 주관적 판단 | → | 📊 데이터 기반 의사결정 |
| ⏰ 1-2일 소요 | → | ⚡ 10분 내 완료 |
| 🎲 불확실한 결과 | → | 🎯 예측 가능한 매칭 |

</div>

---

## 🎥 시연 영상

<div align="center">

https://github.com/user-attachments/assets/55691324-4a27-48f9-a801-8caedbf870b2

<img width="600" alt="Partner Recommendation Interface" src="https://github.com/user-attachments/assets/346848a8-a386-4e2e-8339-32827c2e15ca" />

</div>

---

## ✨ 주요 기능

### 📊 **데이터 기반 지능형 추천**

<table>
<tr>
<th width="50%">핵심 기능</th>
<th width="50%">기술 구현</th>
</tr>
<tr>
<td>

**🎯 다차원 매칭 분석**
- 프로젝트 유형별 전문성 매칭
- 디자인 스타일 선호도 분석
- 예산 범위 적합성 평가
- 지역 및 가용성 고려

**📊 실시간 데이터 연동**
- Opportunity 정보 자동 연계
- 파트너 포트폴리오 실시간 업데이트
- 과거 프로젝트 성과 반영
- 고객 평가 즉시 반영

</td>
<td>

**⚙️ 기술 스택**
```javascript
// 매칭 알고리즘 구조
const matchingEngine = {
  primaryFactors: {
    specialization: 30,  // 전문 분야
    rating: 25,         // 고객 평점
    experience: 20      // 프로젝트 경험
  },
  secondaryFactors: {
    availability: 10    // 가용성
  }
};
```

</td>
</tr>
</table>

### 📈 **상세 매칭 로직**

#### 평가 기준 상세

<div align="center">

| 평가 항목 | 가중치 | 세부 기준 | 데이터 소스 |
|:---:|:---:|:---:|:---:|
| **전문 분야** | 30% | 프로젝트 타입 일치도 | Partner Profile |
| **고객 평점** | 25% | 최근 6개월 평균 | Review Object |
| **프로젝트 경험** | 20% | 유사 프로젝트 수행 이력 | Project History |
| **가용성** | 10% | 현재 진행 프로젝트 수 | Resource Calendar |

</div>

### 🎨 **사용자 인터페이스**

```
┌─────────────────────────────────────────┐
│ 📋 Opportunity 정보                     │
├─────────────────────────────────────────┤
│ 프로젝트명: 강남 부티크 호텔            │
│ 고객사: ABC 호텔 그룹                   │
│ 단계: Proposal/Price Quote              │
│ 예산: ₩500,000,000                      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│ 🏆 추천 파트너 (Top 5)                  │
├─────────────────────────────────────────┤
│ 1. 디자인 스튜디오 A ⭐ 95점            │
│    • 부티크 호텔 전문                   │
│    • 고객 평점: 4.8/5.0                 │
│    • 유사 프로젝트: 12건                │
│                                         │
│ 2. 인테리어 컴퍼니 B ⭐ 92점            │
│    • 럭셔리 호텔 경험                   │
│    • 고객 평점: 4.7/5.0                 │
│    • 유사 프로젝트: 8건                 │
└─────────────────────────────────────────┘
```

---

## 🛠️ 기술 아키텍처

### 시스템 구성도

<div align="center">

```mermaid
graph LR
    subgraph "프론트엔드 (LWC)"
        A[추천 요청 버튼]
        B[결과 표시 UI]
        C[상세 정보 모달]
    end
    
    subgraph "백엔드 (Apex)"
        D[OpportunityController]
        E[PartnerMatcher]
        F[MatchingService]
    end
    
    subgraph "데이터 레이어"
        G[Opportunity]
        H[Partner__c]
        I[Project_History__c]
    end
    
    A --> D
    D --> E
    E --> F
    E --> G
    E --> H
    E --> I
    D --> B
    
    style A fill:#E8F5E9
    style E fill:#FFF3E0
    style F fill:#FCE4EC
```

</div>

### 컴포넌트 구조

```javascript
designPartnerRecommendation/
├── designPartnerRecommendation.html    // UI 템플릿
├── designPartnerRecommendation.js      // 비즈니스 로직
├── designPartnerRecommendation.css     // 스타일링
└── designPartnerRecommendation.js-meta.xml

// Apex Classes
├── DesignPartnerRecommendationController.cls
├── PartnerMatchingService.cls
└── PartnerScoringAlgorithm.cls
```

---

## 💻 구현 상세

### Apex 백엔드 로직

```apex
@AuraEnabled(cacheable=false)
public static Map<String, Object> getRecommendationData(Id opportunityId) {
    // 1. Opportunity 데이터 조회
    Opportunity opp = [
        SELECT Name, ProjectType__c, Customer_Design_Preference__c, 
               sf_product__c, RecommendationDate__c
        FROM Opportunity 
        WHERE Id = :opportunityId
    ];
    
    // 2. 파트너 조회 및 점수 계산
    List<Account> partners = getPartnersWithPriority(opp.ProjectType__c);
    List<PartnerScore> sortedScores = calculateAndSortScores(opp, partners);
    
    // 3. 추천 텍스트 생성
    String aiRecommendation = generateRecommendationText(opp, sortedScores);
    
    // 4. 결과 반환
    return new Map<String, Object>{
        'opportunity' => opp,
        'partners' => extractPartnersFromScores(sortedScores),
        'aiRecommendation' => aiRecommendation
    };
}
```

### LWC 프론트엔드

```javascript
import { LightningElement, api, wire } from 'lwc';
import getRecommendationData from '@salesforce/apex/DesignPartnerRecommendationController.getRecommendationData';

export default class DesignPartnerRecommendation extends LightningElement {
    @api recordId;
    recommendations = [];
    isLoading = false;
    
    async handleGetRecommendation() {
        this.isLoading = true;
        
        try {
            const result = await getRecommendationData({
                opportunityId: this.recordId
            });
            
            if (result.aiRecommendation) {
                this.recommendation = result.aiRecommendation;
            } else {
                this.recommendation = this.generateDetailedRecommendationText(result);
            }
            
            this.showRecommendation = true;
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }
}
```

---

## 📊 매칭 알고리즘 상세

### 점수 계산 로직

```javascript
// 종합 점수 계산 공식 (100점 만점)
const calculateScore = (opportunity, partner) => {
    let score = 50; // 기본 점수
    
    // 프로젝트 타입 매칭 (25점)
    if (partner.AccountRole__c === opportunity.ProjectType__c) {
        score += 25;
    } else if (isRelatedField(partner.AccountRole__c, opportunity.ProjectType__c)) {
        score += 15;
    }
    
    // 디자인 스타일 매칭 (15점)
    if (partner.Design_Style_Specialties__c === opportunity.Customer_Design_Preference__c) {
        score += 15;
    }
    
    // 제품 매칭 (10점)
    if (partner.PartnerSpecialty__c === opportunity.sf_product__c) {
        score += 10;
    }
    
    // 평점 보너스 (최대 10점)
    if (partner.PartnerRating__c) {
        score += Math.floor(partner.PartnerRating__c * 2);
    }
    
    return Math.min(score, 100);
};
```

---

## 🚀 설치 및 설정

### 사전 요구사항

- Salesforce 조직 
- System Administrator 권한
- Apex 및 LWC 배포 권한

### 설치 단계

```bash
# 1. 저장소 클론
git clone https://github.com/YashijaSalesForce/DesignPartnerRecommendation.git

# 2. Salesforce CLI로 인증
sf org login web --alias myOrg --set-default

# 3. 메타데이터 배포
sf project deploy start --source-dir force-app

# 4. 권한 세트 할당
sf org assign permset --name Partner_Recommendation_User

# 5. 샘플 데이터 로드 (선택사항)
sf data import --plan ./data/sample-partners.json
```

### Opportunity 페이지 레이아웃 추가

1. Setup → Object Manager → Opportunity
2. Lightning Record Pages → Edit
3. Components에서 `designPartnerRecommendation` 검색
4. 페이지에 드래그 앤 드롭
5. Save & Activate

---

## ⚙️ 환경 설정

### Custom Metadata 설정

```xml
<!-- Matching_Criteria__mdt -->
<CustomMetadata>
    <label>Default Weights</label>
    <values>
        <field>Specialization_Weight__c</field>
        <value>30</value>
    </values>
    <values>
        <field>Rating_Weight__c</field>
        <value>25</value>
    </values>
    <values>
        <field>Experience_Weight__c</field>
        <value>20</value>
    </values>
</CustomMetadata>
```

---

## 📈 기대 효과

<div align="center">

| 측정 지표 | 개선 전 | 개선 후 | 효과 |
|:---:|:---:|:---:|:---:|
| **파트너 선정 시간** | 1-2일 | 10분 | **의사결정 신속화** |
| **선정 만족도** | 70% | 95% | **품질 향상** |
| **프로젝트 성공률** | 75% | 92% | **리스크 감소** |
| **재작업 비율** | 20% | 5% | **비용 절감** |

</div>

---

## 🔍 문제 해결 (Troubleshooting)

### 자주 발생하는 이슈

<details>
<summary>❓ 추천 결과가 표시되지 않음</summary>

```apex
// Debug 로그 확인
System.debug('Opportunity Data: ' + opp);
System.debug('Available Partners: ' + partners.size());

// 권한 확인
SELECT PermissionSet.Name, Assignee.Name 
FROM PermissionSetAssignment 
WHERE PermissionSet.Name = 'Partner_Recommendation_User'
```

</details>

---

## 🙏 감사의 말

- Salesforce HELP
- Salesforce 청년 CRM 101 과정
-
---

<div align="center">

**💡 더 나은 의사결정을 위한 데이터 기반 파트너 매칭**

[![Stars](https://img.shields.io/github/stars/YashijaSalesForce/DesignPartnerRecommendation?style=social)](https://github.com/YashijaSalesForce/DesignPartnerRecommendation)
[![Issues](https://img.shields.io/github/issues/YashijaSalesForce/DesignPartnerRecommendation?style=social)](https://github.com/YashijaSalesForce/DesignPartnerRecommendation/issues)

</div>
