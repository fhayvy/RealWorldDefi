;; token-trait.clar
;; Define the shared token trait
(define-trait token-trait
  (
    (is-valid-asset-id (uint) (response bool uint))
    (get-balance (principal uint) (response {balance: uint} uint))
    (approve (principal uint uint) (response bool uint))
    (transfer-from (principal principal uint uint) (response bool uint))
  )
)