tact
receive(msg: AdminWithdrawalAllNFTs) {
    require(sender() == self.owner, "Invalid sender");
    require(context().value >= (ton("1") + (self.nftCounter * ton("0.08"))), "Insufficient funds");
    nativeReserve(self.profit, 0);

    let i: Int = 0;
    let body: Transfer = Transfer{
          queryId: msg.queryId,         
          newOwner: self.owner,
          responseDestination: self.owner,
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptySlice()
    };

    while (i < self.nftCounter - 1) {           
      let sentNft: Address = self.nfts.get(i)!!;

      send(SendParameters{
        to: sentNft,
        value: ton("0.06"),
        mode: SendIgnoreErrors + SendPayGasSeparately,
        body: body.toCell()
      });
      //self.nfts.set(i, null);
      i = i + 1;
      
    }

    let lastNft: Address = self.nfts.get(self.nftCounter - 1)!!;

    send(SendParameters{
        to: lastNft,
        value: 0,
        mode: SendIgnoreErrors + SendRemainingBalance,
        body: body.toCell()
    });

    self.nfts = emptyMap();
  }