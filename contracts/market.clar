;; Asset Marketplace Contract
;; This contract allows users to list and trade assets from the main token contract

;; Define the contract owner
(define-data-var contract-owner principal tx-sender)

;; Define listing structure
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    asset-id: uint,
    amount: uint,
    price-per-token: uint,
    active: bool
  }
)

;; Counter for listing IDs
(define-data-var listing-id-nonce uint u0)

;; Define error constants
(define-constant err-unauthorized (err u200))
(define-constant err-invalid-listing (err u201))
(define-constant err-listing-not-found (err u202))
(define-constant err-listing-not-active (err u203))
(define-constant err-insufficient-funds (err u204))
(define-constant err-invalid-price (err u205))
(define-constant err-invalid-amount (err u206))
(define-constant err-not-seller (err u207))

;; Reference to the token contract
(define-constant token-contract .token-contract)

;; Function to create a new listing
(define-public (create-listing (asset-id uint) (amount uint) (price-per-token uint))
  (let
    (
      (listing-id (+ (var-get listing-id-nonce) u1))
      (seller tx-sender)
    )
    ;; Input validation
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> price-per-token u0) err-invalid-price)
    
    ;; Verify asset exists and seller has sufficient balance
    (asserts! (contract-call? token-contract is-valid-asset-id asset-id) err-invalid-listing)
    (asserts! (>= (get balance (contract-call? token-contract get-balance seller asset-id)) amount) 
              err-insufficient-funds)
    
    ;; Create listing
    (map-set listings
      { listing-id: listing-id }
      {
        seller: seller,
        asset-id: asset-id,
        amount: amount,
        price-per-token: price-per-token,
        active: true
      }
    )
    
    ;; Approve marketplace contract to transfer tokens
    (try! (contract-call? token-contract approve (as-contract tx-sender) asset-id amount))
    
    (var-set listing-id-nonce listing-id)
    (ok listing-id)
  )
)

;; Function to cancel a listing
(define-public (cancel-listing (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
      (seller tx-sender)
    )
    ;; Verify sender is the seller
    (asserts! (is-eq (get seller listing) seller) err-not-seller)
    ;; Verify listing is active
    (asserts! (get active listing) err-listing-not-active)
    
    ;; Update listing status
    (map-set listings
      { listing-id: listing-id }
      (merge listing { active: false })
    )
    
    ;; Remove approval
    (try! (contract-call? token-contract approve (as-contract tx-sender) 
           (get asset-id listing) u0))
    
    (ok true)
  )
)

;; Function to purchase from a listing
(define-public (purchase-listing (listing-id uint) (amount uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
      (buyer tx-sender)
      (total-price (* amount (get price-per-token listing)))
    )
    ;; Verify listing is active and amount is valid
    (asserts! (get active listing) err-listing-not-active)
    (asserts! (<= amount (get amount listing)) err-invalid-amount)
    
    ;; Transfer tokens from seller to buyer
    (try! (as-contract (contract-call? token-contract transfer-from 
            (get seller listing) 
            buyer
            (get asset-id listing)
            amount)))
    
    ;; Transfer STX payment from buyer to seller
    (try! (stx-transfer? total-price buyer (get seller listing)))
    
    ;; Update listing amount or deactivate if fully purchased
    (map-set listings
      { listing-id: listing-id }
      (merge listing {
        amount: (- (get amount listing) amount),
        active: (> (- (get amount listing) amount) u0)
      })
    )
    
    (ok true)
  )
)

;; Read-only functions

;; Function to get listing details
(define-read-only (get-listing-details (listing-id uint))
  (map-get? listings { listing-id: listing-id })
)

;; Function to check if listing is active
(define-read-only (is-listing-active (listing-id uint))
  (default-to 
    false
    (get active (default-to 
      { active: false }
      (map-get? listings { listing-id: listing-id })
    ))
  )
)

;; Function to change contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) err-unauthorized)
    (asserts! (not (is-eq new-owner (var-get contract-owner))) err-unauthorized)
    (ok (var-set contract-owner new-owner))
  )
)