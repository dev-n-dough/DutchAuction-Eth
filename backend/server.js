const express = require("express");
const cors = require("cors");
require("dotenv").config();

const auctionRoutes = require("./routes/auctions");
const auctionController = require("./controllers/auctionController");

const app = express();
app.listen(process.env.PORT);

app.use(cors());
app.use(express.json());
app.use("/api/auctions", auctionRoutes);

module.exports = app;