# 1. Создаем новый GCP Проект через CLI
Шаг A: Создаем проект
Имя проекта в GCP должно быть уникальным во всем мире:
```bash
gcloud projects create bug-farm-cloud-450000 --name="Bug Farm Cloud"
```

Шаг B: Фиксируем проект в текущей конфигурации
```bash
gcloud config set project bug-farm-cloud-450000
```

Шаг C: Привязываем Billing Account (Платный аккаунт)
Чтобы создавать виртуалки и сети, к проекту должен быть привязан Billing Account.

Узнаем ID своего Billing-аккаунта:
```bash
gcloud billing accounts list
```
Привязываем его к новому проекту:
```bash
gcloud billing projects link bug-farm-cloud-450000 \
  --billing-account=XXXXXX-XXXXXX-XXXXXX
```

Шаг D: Включаем необходимые GCP API
По умолчанию в новом проекте выключены сервисы виртуализации и IAP-туннелей. Включаем их:
```bash
gcloud services enable compute.googleapis.com iap.googleapis.com
```

# 2. Создаем Бакет под Terraform State
Cоздаем бакет для хранения tfstate (из backend.tf):

```bash
gcloud storage buckets create gs://bug-farm-tfstate-gcp \
  --location=europe-west3 \
  --uniform-bucket-level-access
```

# 3. Настройка Workload Identity Federation (WIF) в GCP
Нужно разрешить репозиторию запрашивать временные токены у GCP

Шаг A: Фиксируем переменные под проект и репозиторий
```bash
PROJECT_ID="bug-farm-cloud-450000" # real Project ID
GITHUB_REPO="ViktorovPavel/bug-farm-cloud-infra" # GitHub USER/REPO
```

Шаг B: Включаем необходимые API для IAM и Federated Auth
```bash
gcloud services enable iamcredentials.googleapis.com \
                       iam.googleapis.com \
                       sts.googleapis.com --project="${PROJECT_ID}"
```

Шаг C: Создаем Service Account для Terraform
```bash
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Automation Service Account" \
    --project="${PROJECT_ID}"
```

Шаг D: Выдаем Service Account необходимые роли (Compute Admin + Storage Admin для tfstate)
```bash
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.objectAdmin"
```

Шаг E: Создаем Workload Identity Pool
```bash
gcloud iam workload-identity-pools create "github-actions-pool" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --display-name="GitHub Actions Pool"
```

Шаг F: Создаем Workload Identity Provider внутри пула
```bash
pavel@HP-Latitude-5490:~/PycharmProjects/bug-farm-cloud-infra$ gcloud iam workload-identity-pools providers create-oidc "github-provider" \
    --project="${PROJECT_ID}" \
    --location="global" \
    --workload-identity-pool="github-actions-pool" \
    --display-name="GitHub Actions Provider" \
    --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.owner=assertion.repository_owner" \
    --attribute-condition="assertion.repository == '${GITHUB_REPO}'" \
    --issuer-uri="https://token.actions.githubusercontent.com"
```

Шаг G: Связываем наш GitHub репозиторий с Service Account
```bash
gcloud iam service-accounts add-iam-policy-binding "terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --project="${PROJECT_ID}" \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_REPO}"
```

# 4. Переменные для GitHub Secrets / Variables
Добавим два значение в настройки репозитория GitHub (Settings -> Secrets and variables -> Actions):

Узнать полный путь (GCP_WORKLOAD_IDENTITY_PROVIDER): 
```bash
gcloud iam workload-identity-pools providers describe github-provider --workload-identity-pool=github-actions-pool --location=global --format='value(name)')
```

В раздел Variables (Repository variables):
```text
GCP_PROJECT_ID = bug-farm-cloud-450000
GCP_WORKLOAD_IDENTITY_PROVIDER = projects/922224583976/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider
GCP_SERVICE_ACCOUNT = terraform-sa@bug-farm-cloud-450000.iam.gserviceaccount.com
```
