;; Tokenized Multi-Asset Management Platform

;; Define the asset structure
(define-map assets
  { asset-id: uint }
  {
    name: (string-ascii 64),
    type: (string-ascii 32),
    total-supply: uint,
    price: uint
  }
)

;; Define ownership structure
(define-map holdings
  { owner: principal, asset-id: uint }
  { balance: uint }
)

;; Define error constants
(define-constant err-unauthorized (err u100))
(define-constant err-asset-exists (err u101))
(define-constant err-asset-not-found (err u102))
(define-constant err-insufficient-balance (err u103))

;; Counter for asset IDs
(define-data-var asset-id-nonce uint u0)

;; Function to create a new asset
(define-public (create-asset (name (string-ascii 64)) (type (string-ascii 32)) (total-supply uint) (price uint))
  (let
    (
      (asset-id (+ (var-get asset-id-nonce) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-none (map-get? assets { asset-id: asset-id })) err-asset-exists)
    (map-set assets
      { asset-id: asset-id }
      { name: name, type: type, total-supply: total-supply, price: price }
    )
    (map-set holdings
      { owner: contract-owner, asset-id: asset-id }
      { balance: total-supply }
    )
    (var-set asset-id-nonce asset-id)
    (ok asset-id)
  )
)

;; Function to transfer tokens
(define-public (transfer (to principal) (asset-id uint) (amount uint))
  (let
    (
      (sender-balance (get balance (map-get? holdings { owner: tx-sender, asset-id: asset-id })))
      (recipient-balance (get balance (default-to { balance: u0 } (map-get? holdings { owner: to, asset-id: asset-id }))))
    )
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (map-set holdings
      { owner: tx-sender, asset-id: asset-id }
      { balance: (- sender-balance amount) }
    )
    (map-set holdings
      { owner: to, asset-id: asset-id }
      { balance: (+ recipient-balance amount) }
    )
    (ok true)
  )
)

;; Function to get asset details
(define-read-only (get-asset-details (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Function to get user balance for an asset
(define-read-only (get-balance (owner principal) (asset-id uint))
  (default-to { balance: u0 } (map-get? holdings { owner: owner, asset-id: asset-id }))
)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Function to change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)
