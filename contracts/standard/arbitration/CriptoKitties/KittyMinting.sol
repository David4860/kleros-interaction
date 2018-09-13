/**
 *  @title All functions related to creating kittens
 *  @author dapperlabs (https://github.com/dapperlabs)
 *  This code was taken from https://github.com/dapperlabs at
 *  https://github.com/dapperlabs/cryptokitties-bounty and is NOT kleros code.
 */
pragma solidity ^0.4.18;

// Auction wrapper functions
import "./KittyAuction.sol";

/// @title all functions related to creating kittens
contract KittyMinting is KittyAuction {

    // Limits the number of cats the contract owner can ever create.
    uint256 public promoCreationLimit = 5000;
    uint256 public gen0CreationLimit = 50000;

    // Constants for gen0 auctions.
    uint256 public gen0StartingPrice = 10 finney;
    uint256 public gen0AuctionDuration = 1 days;

    // Counts the number of cats the contract owner has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /// @dev we can create promo kittens, up to a limit. Only callable by COO
    /// @param _genes the encoded genes of the kitten to be created, any value is accepted
    /// @param _owner the future owner of the created kittens. Default to contract COO
    function createPromoKitty(uint256 _genes, address _owner) public onlyCOO {
        address owner = _owner;

        if (owner == address(0)) {
            owner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit, "Already created too many promo kittens.");
        require(gen0CreatedCount < gen0CreationLimit, "Already created too many generation zero kittens.");

        promoCreatedCount++;
        gen0CreatedCount++;
        _createKitty(0, 0, 0, _genes, owner);
    }

    /// @dev Creates a new gen0 kitty with the given genes and
    ///  creates an auction for it.
    function createGen0Auction(uint256 _genes) public onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit, "Already created too many generation zero kittens.");

        uint256 kittyId = _createKitty(0, 0, 0, _genes, address(this));
        _approve(kittyId, saleAuction);

        saleAuction.createAuction(
            kittyId,
            _computeNextGen0Price(),
            0,
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    /// @dev Computes the next gen0 auction starting price, given
    ///  the average of the past 5 prices + 50%.
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        // sanity check to ensure we don't overflow arithmetic (this big number is 2^128-1).
        require(avePrice < 340282366920938463463374607431768211455, "Unsigned integer overflow.");

        uint256 nextPrice = avePrice + (avePrice / 2);

        // We never auction for less than starting price
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}
