;; Security Analyst Verification Contract
;; Manages verification and roles of security analysts

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Analyst levels
(define-constant analyst-level-junior u1)
(define-constant analyst-level-senior u2)
(define-constant analyst-level-lead u3)

;; Data structures
(define-map analysts
  { analyst: principal }
  {
    verified: bool,
    level: uint,
    specialization: (string-ascii 50),
    verification-date: uint,
    active: bool
  }
)

(define-map analyst-tokens
  { analyst: principal }
  { token-id: uint, issued-at: uint }
)

(define-data-var next-token-id uint u1)

;; Verify a security analyst
(define-public (verify-analyst (analyst principal) (level uint) (specialization (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= level analyst-level-lead) (err u104))
    (let ((token-id (var-get next-token-id)))
      (map-set analysts
        { analyst: analyst }
        {
          verified: true,
          level: level,
          specialization: specialization,
          verification-date: block-height,
          active: true
        }
      )
      (map-set analyst-tokens
        { analyst: analyst }
        { token-id: token-id, issued-at: block-height }
      )
      (var-set next-token-id (+ token-id u1))
      (ok token-id)
    )
  )
)

;; Check if analyst is verified
(define-read-only (is-verified-analyst (analyst principal))
  (match (map-get? analysts { analyst: analyst })
    analyst-data (and (get verified analyst-data) (get active analyst-data))
    false
  )
)

;; Get analyst details
(define-read-only (get-analyst-info (analyst principal))
  (map-get? analysts { analyst: analyst })
)

;; Get analyst token
(define-read-only (get-analyst-token (analyst principal))
  (map-get? analyst-tokens { analyst: analyst })
)

;; Deactivate analyst
(define-public (deactivate-analyst (analyst principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? analysts { analyst: analyst })
      analyst-data
        (begin
          (map-set analysts
            { analyst: analyst }
            (merge analyst-data { active: false })
          )
          (ok true)
        )
      err-not-found
    )
  )
)
