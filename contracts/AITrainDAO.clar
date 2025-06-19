(define-fungible-token ai-train-token u1000000)

;; Data Map: Stores AI training jobs
(define-map ai-training-jobs 
    {job-id: uint} 
    {creator: principal, stake: uint, completed: bool})

;; Data Map: Stores AI model contributors and their compute power
(define-map contributors 
    {job-id: uint, contributor: principal} 
    {compute-power: uint, reward: uint})

;; Data Map: AI model ownership and storage reference
(define-map ai-models 
    {model-id: uint} 
    {owner: principal, storage-link: (string-ascii 256)})

;; Constants
(define-constant contract-owner 'SP000000000000000000002Q6VF78) ;; Replace with actual contract owner address
(define-constant ERR-INSUFFICIENT-STAKE (err u1))
(define-constant ERR-TRANSFER-FAILED (err u2))
(define-constant ERR-JOB-NOT-FOUND (err u3))
(define-constant ERR-MINT-FAILED (err u4))
(define-constant ERR-MODEL-EXISTS (err u5))
(define-constant ERR-NOT-OWNER (err u6))
(define-constant ERR-MODEL-NOT-FOUND (err u7))
(define-constant ERR-INVALID-JOB-ID (err u8))
(define-constant ERR-INVALID-STAKE (err u9))
(define-constant ERR-INVALID-COMPUTE (err u10))
(define-constant ERR-INVALID-MODEL-ID (err u11))
(define-constant ERR-INVALID-STORAGE (err u12))
(define-constant ERR-INVALID-RECIPIENT (err u13))

;; Event Logs
(define-data-var job-submitted (tuple (job-id uint) (creator principal)) {job-id: u0, creator: contract-owner})
(define-data-var training-completed (tuple (job-id uint) (winner principal)) {job-id: u0, winner: contract-owner})
(define-data-var model-minted (tuple (model-id uint) (owner principal)) {model-id: u0, owner: contract-owner})

;; Function: Submit AI Training Job
(define-public (submit-training-job (job-id uint) (stake uint))
    (begin
        (asserts! (> job-id u0) ERR-INVALID-JOB-ID)
        (asserts! (>= stake u100) ERR-INSUFFICIENT-STAKE)
        (match (ft-transfer? ai-train-token stake tx-sender contract-owner)
            success (begin
                (map-set ai-training-jobs {job-id: job-id} 
                         {creator: tx-sender, stake: stake, completed: false})
                (var-set job-submitted {job-id: job-id, creator: tx-sender})
                (print (var-get job-submitted))
                (ok job-id))
            error ERR-TRANSFER-FAILED)
    )
)

;; Function: Contribute Compute Power
(define-public (contribute-training (job-id uint) (compute-power uint))
    (begin
        (asserts! (> job-id u0) ERR-INVALID-JOB-ID)
        (asserts! (> compute-power u0) ERR-INVALID-COMPUTE)
        (asserts! (is-some (map-get? ai-training-jobs {job-id: job-id})) ERR-JOB-NOT-FOUND)
        (map-set contributors {job-id: job-id, contributor: tx-sender} 
                 {compute-power: compute-power, reward: u0})
        (ok compute-power)
    )
)

;; Function: Complete Training & Distribute Rewards
(define-public (complete-training (job-id uint) (winner principal))
    (begin
        (asserts! (> job-id u0) ERR-INVALID-JOB-ID)
        (asserts! (is-some (map-get? ai-training-jobs {job-id: job-id})) ERR-JOB-NOT-FOUND)
        (asserts! (not (is-eq winner contract-owner)) ERR-INVALID-RECIPIENT)
        (map-set ai-training-jobs {job-id: job-id} {creator: tx-sender, stake: u0, completed: true})
        (match (ft-mint? ai-train-token u500 winner)
            success (begin
                (var-set training-completed {job-id: job-id, winner: winner})
                (print (var-get training-completed))
                (ok job-id))
            error ERR-MINT-FAILED)
    )
)

;; Function: Mint AI Model NFT
(define-public (mint-ai-model (model-id uint) (storage-link (string-ascii 256)))
    (begin
        (asserts! (> model-id u0) ERR-INVALID-MODEL-ID)
        (asserts! (not (is-eq storage-link "")) ERR-INVALID-STORAGE)
        (asserts! (is-none (map-get? ai-models {model-id: model-id})) ERR-MODEL-EXISTS)
        (map-set ai-models {model-id: model-id} {owner: tx-sender, storage-link: storage-link})
        (var-set model-minted {model-id: model-id, owner: tx-sender})
        (print (var-get model-minted))
        (ok model-id)
    )
)

;; Function: Transfer AI Model NFT
(define-public (transfer-ai-model (model-id uint) (recipient principal))
    (begin
        (asserts! (> model-id u0) ERR-INVALID-MODEL-ID)
        (asserts! (not (is-eq recipient contract-owner)) ERR-INVALID-RECIPIENT)
        (let ((model (map-get? ai-models {model-id: model-id})))
            (match model model-data
                (begin
                    (asserts! (is-eq (get owner model-data) tx-sender) ERR-NOT-OWNER)
                    (map-set ai-models {model-id: model-id} 
                             {owner: recipient, storage-link: (get storage-link model-data)})
                    (ok recipient))
                ERR-MODEL-NOT-FOUND)
        )
    )
)
