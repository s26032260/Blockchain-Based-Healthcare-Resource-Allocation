;; Facility Verification Contract
;; Validates healthcare providers on the blockchain

(define-data-var admin principal tx-sender)

;; Facility status: 0 = unverified, 1 = verified, 2 = suspended
(define-map facilities
  { facility-id: (string-ascii 64) }
  {
    name: (string-ascii 100),
    address: (string-ascii 256),
    license-number: (string-ascii 64),
    status: uint,
    verification-date: uint
  }
)

;; Read-only function to check if a facility is verified
(define-read-only (is-facility-verified (facility-id (string-ascii 64)))
  (let ((facility (map-get? facilities { facility-id: facility-id })))
    (if (is-some facility)
      (is-eq (get status (unwrap-panic facility)) u1)
      false
    )
  )
)

;; Get facility details
(define-read-only (get-facility (facility-id (string-ascii 64)))
  (map-get? facilities { facility-id: facility-id })
)

;; Register a new facility (unverified by default)
(define-public (register-facility
    (facility-id (string-ascii 64))
    (name (string-ascii 100))
    (address (string-ascii 256))
    (license-number (string-ascii 64))
  )
  (begin
    (asserts! (not (is-some (map-get? facilities { facility-id: facility-id }))) (err u1)) ;; Facility ID already exists
    (ok (map-set facilities
      { facility-id: facility-id }
      {
        name: name,
        address: address,
        license-number: license-number,
        status: u0,
        verification-date: u0
      }
    ))
  )
)

;; Verify a facility (admin only)
(define-public (verify-facility (facility-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Not authorized
    (asserts! (is-some (map-get? facilities { facility-id: facility-id })) (err u404)) ;; Facility not found
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge (unwrap-panic (map-get? facilities { facility-id: facility-id }))
        {
          status: u1,
          verification-date: block-height
        }
      )
    ))
  )
)

;; Suspend a facility (admin only)
(define-public (suspend-facility (facility-id (string-ascii 64)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Not authorized
    (asserts! (is-some (map-get? facilities { facility-id: facility-id })) (err u404)) ;; Facility not found
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge (unwrap-panic (map-get? facilities { facility-id: facility-id }))
        { status: u2 }
      )
    ))
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)
