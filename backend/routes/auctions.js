const express = require("express");
const { getAllAuctions, getAuction, getAuctionPrice, createAuction, buyNft } = require("../controllers/auctionController");

const router = express.Router();

// GET /api/auctions 
router.get("/", getAllAuctions);

router.get("/:id", getAuction);

router.get("/:id/price", getAuctionPrice);

router.post("/", createAuction);

router.post("/:id/buy", buyNft);

module.exports = router;