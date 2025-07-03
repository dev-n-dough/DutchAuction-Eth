const {contract, contractWithSigner, parseContractError, ethers, contract_userIsSender} = require("../config/config.js");

class AuctionController {
    // GET /auctions => fetches all open auctions
    async getAllAuctions(req,res){
        try{
            const tokenCounter = await contract.getTokenCounter();
            const auctions = []

            for(let i=0; i<tokenCounter;i++){
                try{
                    const nftData = await contract.getNftData(i);
                    const currentPrice = Number(nftData.state) == 0 ? ethers.formatEther(await contract.getPrice(i)) : "0"; // formatEther returns a string
                    auctions.push({
                        id : i,
                        startTime : Number(nftData.startTime),
                        state : Number(nftData.state) == 0 ? "OPEN" : "CLOSED",
                        currentPrice : currentPrice,
                        expired : Number(nftData.state) == 0 && currentPrice == "0"
                    });
                } catch(e) {
                    console.log(`Error fetchion auction ${i}`, e.message);
                }
            }

            res.json({
                success : true,
                data : auctions,
                number : auctions.length
            })
        } catch(e) {
            res.json({
                success : false,
                error : e.message
            });
        }
    }

    // GET /auction/:id
    async getAuction(req,res) {
        const {id} = req.params;
        const tokenId = parseInt(id);

        if(isNaN(tokenId) || tokenId < 0){
            res.json({
                success : false,
                message : "Invalid auction id"
            });
        }
        
        const nftData = await contract.getNftData(tokenId);
        const priceWei = (await Number(nftData.state) == 0) 
                        ? (await contract.getPrice(tokenId))
                        : "0";  
        const price = parseFloat(ethers.formatEther(priceWei));

        res.json({
            success : true,
            data : {
                id : tokenId,
                price : price,
                priceWei : priceWei.toString(),
                startTime : Number(nftData.startTime),
                expired : Number(nftData.state) == 0 && price == "0"
            }
        });
    }

    // GET /auction/:id/price
    async getAuctionPrice(req,res){
        try{
            const {id} = req.params;
            const tokenId = parseInt(id);

            if(isNaN(tokenId) || tokenId < 0){
                return res.status(400).json({
                    success : false,
                    message : "Invalid auction ID sent!"
                });
            }

            const priceWei = await contract.getPrice(tokenId);
            const price = parseFloat(ethers.formatEther(priceWei));

            res.json({
                success : true,
                data : {
                    id : id,
                    price : price,
                    priceInWei : priceWei.toString()
                }
            })
        } catch(e){
            res.json({
                success : false,
                error : e.message
            });
        }
    }

    // POST /auctions
    async createAuction(req,res){
        const tx = await contractWithSigner.createAuction(); // e make sure you call state changing functions using `contractWithSigner`. This is function contains access controls, but will pass since the pvt key is same as the one which I used to deploy the contract 
        const receipt = await tx.wait();
        const tokenCounter = await contract.getTokenCounter();

        res.json({
            success : true,
            data : {
                newAuctionId : Number(tokenCounter) - 1,
                transactionHash : tx.hash,
                receipt : receipt
            }
        });
    }

    // POST /auctions/:id/buy
    async buyNft(req,res){
        const {id} = req.params;
        const tokenId = parseInt(id);

        if(isNaN(tokenId) || tokenId < 0){
            return res.status(400).json({
                success : false,
                message : "Invalid auction ID sent!"
            });
        }

        const currentPriceWei = await contract.getPrice(tokenId);
        const currentPrice = parseFloat(ethers.formatEther(currentPriceWei));

        const bufferWei = currentPriceWei * BigInt(101) / BigInt(100);
        
        if (currentPrice === 0) {
            return res.status(400).json({
            success: false,
            error: 'Auction has expired or is closed'
            });
        }

        const tx = await contract_userIsSender.buy(tokenId, {value : bufferWei});
        const receipt = await tx.wait();

        res.json({
            success : true,
            data : {
                auctionId : tokenId,
                purchasePrice : currentPrice,
                transactionHash : tx.hash,
                receipt : receipt
            }
        })
    }
}

module.exports = new AuctionController();