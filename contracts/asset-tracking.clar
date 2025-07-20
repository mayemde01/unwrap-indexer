;; asset-tracking
;; 
;; The Unwrap Indexer's core contract for decentralized asset tracking and verification.
;; Enables secure, transparent registration, transfer, and comprehensive tracking of assets
;; with granular metadata and immutable provenance records.

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ASSET-NOT-FOUND (err u101))
(define-constant ERR-INVALID-DETAILS (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-UNAUTHORIZED-TRANSFER (err u104))
(define-constant ERR-INVALID-RECEIVER (err u105))
(define-constant ERR-UNAUTHORIZED-ATTESTATION (err u106))

;; Data structures

;; Counter for asset IDs
(define-data-var asset-id-counter uint u0)

;; Asset metadata structure
(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    description: (string-ascii 256),
    value: uint,
    date-acquired: uint,
    condition: (string-ascii 64),
    metadata-uri: (optional (string-utf8 256)),
    is-active: bool
  }
)

;; Tracks history of ownership transfers for each asset
(define-map asset-history
  { asset-id: uint, index: uint }
  {
    previous-owner: principal,
    new-owner: principal,
    transfer-date: uint,
    notes: (optional (string-ascii 256))
  }
)

;; Tracks number of history entries for each asset
(define-map asset-history-counter
  { asset-id: uint }
  { count: uint }
)

;; Attestations made by third parties (insurers, appraisers, etc.)
(define-map asset-attestations
  { asset-id: uint, index: uint }
  {
    attester: principal,
    attestation-type: (string-ascii 64),
    attestation-date: uint,
    details: (string-utf8 256),
    uri: (optional (string-utf8 256))
  }
)

;; Tracks number of attestations for each asset
(define-map asset-attestation-counter
  { asset-id: uint }
  { count: uint }
)

;; Map to track assets owned by each principal
(define-map principal-assets
  { owner: principal }
  { asset-ids: (list 100 uint) }
)

;; Private functions

;; Generate a new unique asset ID
(define-private (generate-asset-id)
  (let ((current-id (var-get asset-id-counter)))
    (var-set asset-id-counter (+ current-id u1))
    current-id
  )
)

;; Add a history entry for an asset transfer
(define-private (add-history-entry (asset-id uint) (previous-owner principal) (new-owner principal) (notes (optional (string-ascii 256))))
  (let ((counter (default-to { count: u0 } (map-get? asset-history-counter { asset-id: asset-id })))
        (index (get count counter)))
    ;; Add history entry
    (map-set asset-history
      { asset-id: asset-id, index: index }
      {
        previous-owner: previous-owner,
        new-owner: new-owner,
        transfer-date: block-height,
        notes: notes
      }
    )
    ;; Update counter
    (map-set asset-history-counter
      { asset-id: asset-id }
      { count: (+ index u1) }
    )
  )
)

;; Check if a principal is the owner of an asset
(define-private (is-owner (asset-id uint) (user principal))
  (let ((asset (map-get? assets { asset-id: asset-id })))
    (and
      (is-some asset)
      (is-eq user (get owner (unwrap-panic asset)))
    )
  )
)

;; Read-only functions

;; Get asset details by ID
(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Get all assets owned by a principal
(define-read-only (get-assets-by-owner (owner principal))
  (default-to { asset-ids: (list) } (map-get? principal-assets { owner: owner }))
)

;; Get asset history length
(define-read-only (get-asset-history-length (asset-id uint))
  (default-to { count: u0 } (map-get? asset-history-counter { asset-id: asset-id }))
)

;; Get specific history entry for an asset
(define-read-only (get-asset-history-entry (asset-id uint) (index uint))
  (map-get? asset-history { asset-id: asset-id, index: index })
)

;; Get asset attestation length
(define-read-only (get-asset-attestation-length (asset-id uint))
  (default-to { count: u0 } (map-get? asset-attestation-counter { asset-id: asset-id }))
)

;; Get specific attestation for an asset
(define-read-only (get-asset-attestation (asset-id uint) (index uint))
  (map-get? asset-attestations { asset-id: asset-id, index: index })
)

;; Check if an asset exists
(define-read-only (asset-exists (asset-id uint))
  (is-some (map-get? assets { asset-id: asset-id }))
)

;; Public functions

;; Update asset details (only owner can update)
(define-public (update-asset
                (asset-id uint)
                (description (string-ascii 256))
                (value uint)
                (condition (string-ascii 64))
                (metadata-uri (optional (string-utf8 256))))
  (let ((asset (map-get? assets { asset-id: asset-id })))
    ;; Check asset exists
    (asserts! (is-some asset) ERR-ASSET-NOT-FOUND)
    
    ;; Check ownership
    (asserts! (is-owner asset-id tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Validate inputs
    (asserts! (> (len description) u0) ERR-INVALID-DETAILS)
    (asserts! (> value u0) ERR-INVALID-DETAILS)
    
    ;; Update the asset
    (map-set assets
      { asset-id: asset-id }
      (merge (unwrap-panic asset)
        {
          description: description,
          value: value,
          condition: condition,
          metadata-uri: metadata-uri
        }
      )
    )
    
    (ok true)
  )
)

;; Add an attestation to an asset
(define-public (add-attestation
                (asset-id uint)
                (attestation-type (string-ascii 64))
                (details (string-utf8 256))
                (uri (optional (string-utf8 256))))
  (let ((asset (map-get? assets { asset-id: asset-id }))
        (counter (default-to { count: u0 } (map-get? asset-attestation-counter { asset-id: asset-id })))
        (index (get count counter)))
    
    ;; Check asset exists
    (asserts! (is-some asset) ERR-ASSET-NOT-FOUND)
    
    ;; Validate attestation inputs
    (asserts! (> (len attestation-type) u0) ERR-INVALID-DETAILS)
    (asserts! (> (len details) u0) ERR-INVALID-DETAILS)
    
    ;; Add attestation
    (map-set asset-attestations
      { asset-id: asset-id, index: index }
      {
        attester: tx-sender,
        attestation-type: attestation-type,
        attestation-date: block-height,
        details: details,
        uri: uri
      }
    )
    
    ;; Update counter
    (map-set asset-attestation-counter
      { asset-id: asset-id }
      { count: (+ index u1) }
    )
    
    (ok index)
  )
)

;; Deactivate an asset (mark as lost, stolen, or destroyed)
(define-public (deactivate-asset
                (asset-id uint)
                (reason (string-ascii 256)))
  (let ((asset (map-get? assets { asset-id: asset-id })))
    ;; Check asset exists
    (asserts! (is-some asset) ERR-ASSET-NOT-FOUND)
    
    ;; Check ownership
    (asserts! (is-owner asset-id tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Update the asset status
    (map-set assets
      { asset-id: asset-id }
      (merge (unwrap-panic asset) { is-active: false })
    )
    
    ;; Add note to history
    (add-history-entry 
      asset-id 
      tx-sender 
      tx-sender 
      (some reason)
    )
    
    (ok true)
  )
)

;; Reactivate an asset
(define-public (reactivate-asset
                (asset-id uint)
                (reason (string-ascii 256)))
  (let ((asset (map-get? assets { asset-id: asset-id })))
    ;; Check asset exists
    (asserts! (is-some asset) ERR-ASSET-NOT-FOUND)
    
    ;; Check ownership
    (asserts! (is-owner asset-id tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Update the asset status
    (map-set assets
      { asset-id: asset-id }
      (merge (unwrap-panic asset) { is-active: true })
    )
    
    ;; Add note to history
    (add-history-entry 
      asset-id 
      tx-sender 
      tx-sender 
      (some reason)
    )
    
    (ok true)
  )
)