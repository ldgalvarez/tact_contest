import "@stdlib/deploy";

/*
  TASK 4 - NFT locker
  Implement a smart contract that will lock NFT for a period of time specified by the owner.
  Smart conrtact should contain logic to process following messages and getters: 

  Messages: 
  * OwnershipAssigned
   - Recives nft + time (in a forwardPayload message as uint32) for which this nft will be locked + address of the sender of the nft (prevOwner).
   - If the smart contract already holds an nft then return the incoming nft back to the sender
  * NftWithdrawal
   - Request withdrawal of the locked nft
   - If sender is not the owner (that came from OwnershipAssigned as prevOwner address) then throw "Invalid sender" 
   - If time has not passed then send message back to the sender with the comment "NFT is still locked" according to the TON's "message with text comment" standard 
   - Otherwise (all good) send the locked nft back to the owner with all the remaining TON balance
   Note that the order of checks is important
   (in case: "sender is not the owner" and "time has not passed" at the same time, "Invalid sender" error takes priority)

  Getters:
  * time
   - get how much lock time is left
  * nft
   - get the address of the locked nft 
  * owner
   - get the owner of the locked nft (that came from OwnershipAssigned as prevOwner)
*/
/*
  TAREA 4 - Casillero NFT
  Implemente un contrato inteligente que bloqueará NFT durante un período de tiempo especificado por el propietario.
  El contacto inteligente debe contener lógica para procesar los siguientes mensajes y captadores:

  Mensajes:
  *PropiedadAsignada
   - Recibe nft + hora (en un mensaje forwardPayload como uint32) durante el cual se bloqueará este nft + dirección del remitente del nft (prevOwner).
   - Si el contrato inteligente ya contiene un nft, devuelva el nft entrante al remitente
  * NftRetiro
   - Solicitar retiro del nft bloqueado
   - Si el remitente no es el propietario (que proviene de OwnershipAssigned como dirección del propietario anterior), entonces arroja "Remitente no válido".
   - Si no ha pasado el tiempo, envíe el mensaje al remitente con el comentario "NFT todavía está bloqueado" de acuerdo con el estándar de "mensaje con comentario de texto" de TON
   - De lo contrario (todo bien) envíe el nft bloqueado al propietario con todo el saldo de TON restante
   Tenga en cuenta que el orden de los controles es importante.
   (en caso de que "el remitente no es el propietario" y "no ha pasado el tiempo" al mismo tiempo, el error "Remitente no válido" tiene prioridad)

  Captadores:
  * tiempo
   - obtener cuánto tiempo de bloqueo queda
  * nft
   - obtener la dirección del nft bloqueado
  * dueño
   - obtener el propietario del nft bloqueado (que proviene de OwnershipAssigned como prevOwner)
*/

message(0x05138d91) OwnershipAssigned {
    queryId: Int as uint64;
    prevOwner: Address;
    forwardPayload: Slice as remaining; 
}

message(0x5fcc3d14) Transfer { 
    queryId: Int as uint64;            
    newOwner: Address; 
    responseDestination: Address; 
    customPayload: Cell?; 
    forwardAmount: Int as coins; 
    forwardPayload: Slice as remaining; 
}

message NftWithdrawal {
  queryId: Int as uint64;
  nftAddress: Address;
}

contract Task4 with Deployable {
  seed: Int as uint128;
  block_time: Int;
  nft: Address?;
  nft_owner: Address?;
  
  init(seed: Int) {
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address
    self.block_time = 0;
  }

  receive(msg: OwnershipAssigned) {
    if(self.nft == null){
      self.nft = sender();
      self.block_time = msg.forwardPayload.loadUint(32) + now();
      self.nft_owner = msg.prevOwner;
    }
    else{
      send(SendParameters{
        to: msg.prevOwner,
        value: 0, 
        mode: SendIgnoreErrors + SendRemainingValue, 
        bounce: true, 
        body: Transfer{
          queryId: msg.queryId,
          newOwner: msg.prevOwner,
          responseDestination: myAddress(),
          customPayload: null,
          forwardAmount: 0,
          forwardPayload: emptyCell().asSlice()
        }.toCell()
      });
    }

  }

  receive(msg: NftWithdrawal) {
    require(nft_owner == seder(),"Invalid sender");
    require(self.block_time - now() <= 0,"NFT is still locked");
    // require(msg.nftAddress == self.nft)

    send(SendParameters{
      to: msg.,
      value: 0, 
      mode: SendIgnoreErrors + SendRemainingValue, 
      bounce: true, 
      body: Transfer{
        queryId: msg.queryId,
        newOwner: msg.prevOwner,
        responseDestination: myAddress(),
        customPayload: null,
        forwardAmount: 0,
        forwardPayload: emptyCell().asSlice()
      }.toCell()
    });
  }

  get fun time(): Int {
    if(self.block_time - now() <= 0){
      return 0;
    } 
    else{
      return self.block_time - now();
    }
  }

  get fun nft(): Address? {
    if(self.nft != null){
      return self.nft!!;
    }
  }

  get fun owner(): Address? {
    if(self.nft_owner != null){
      return self.nft_owner!!;
    }
  }
}