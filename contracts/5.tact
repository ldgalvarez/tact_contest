import "@stdlib/deploy";
/*
  TASK 5 - NFT random swap 
  The smart contract contains a bunch of different NFTs.
  A user brings his NFT (sends it to the smart contract), with 2.1 TON (2 for admin's profit, 0.1 for gas) in attachment (as fee for swap).
  The smart contract randomly chooses some NFT from the available NFTs (including the newly incoming one) and gives it to the user in exchange for the brought NFT (but occasionally just returns user's NFT in some cases).
  Admin can deposit NFTs without swap logic. Any NFT received from the admin is considered deposited. Admin can't swap.
  Admin can withdraw all NFTs at once, and also all TONs collected from users as fees.
  Implement getter that will return NFT addresses held by the smart contract.
  Implement getter that will return the amount of admin`s profit collected.

  In details, the smart contract (later: SC) should have this logic:
  Messages
  * AdminWithdrawalProfit 
   - SC should check that sender is the admin / otherwise throw "Insufficient privelegies"
   - SC should send all collected fees to admin except 0.1 TON (use AdminFetchProfit message as body)
     In other words: after each such operation, the contract's balance should be equal to 0.1 TON (which are reserved for storage) and the rest should be sent to the admin
  * AdminWithdrawalAllNFTs
   - SC should check that incoming tx TON value is enough for NFT withdrawal. Specifically, at least: (1 + totalNftsHeld * 0.08) TONs. Otherwise throw "Insufficent funds"
   - SC should check that sender is the admin, throw "Invalid sender" otherwise
   - If all checks pass, SC should send NFTs one by one to the admin 
   - SC should be able to withdraw all NFTs by a single message from admin
  * OwnershipAssigned 
   - if prevOwner is the owner's (admin) address, then add NFT to the collection
   - if value of TON attached is less then 2.1 TON then stop execution and return NFT back,
     but only in case that TON attached is enough to process refund without losing TONs on the SC's balance
   - randomly select NFT to send from all the NFTs that smart contract has
   - send the selected NFT to the sender with all remaining balance (except for admin profit = fees collected from this and other swaps)
     In other words: the contract's balance should increase by exactly 2 TON, some incoming TONs will be consumed for gas and the remainings of the incoming TONs should be refunded to the sender
  
  Getters
  * profit
   - returns how much collected fees is available to withdraw for the admin (all fees minus 0.1 TON)
  * nfts
   - returns dict of held NFTs with NFT indexes (sequential numbers from 0, 1, 2 ... and up to 'totalNftsHeld-1') as keys and NFT address as values 
     the order of NFTs in this dictionary doesn't matter
*/
/*
  TAREA 5: intercambio aleatorio de NFT
  El contrato inteligente contiene un montón de NFT diferentes.
  Un usuario trae su NFT (lo envía al contrato inteligente), con 2,1 TON (2 para beneficio del administrador, 0,1 para gasolina) adjunto (como tarifa por intercambio).
  El contrato inteligente elige aleatoriamente algunos NFT de los NFT disponibles (incluido el recién entrante) y se los entrega al usuario a cambio del NFT traído (pero ocasionalmente solo devuelve el NFT del usuario en algunos casos).
  El administrador puede depositar NFT sin lógica de intercambio. Cualquier NFT recibido del administrador se considera depositado. El administrador no puede intercambiar.
  El administrador puede retirar todos los NFT a la vez y también todos los TON cobrados a los usuarios como tarifas.
  Implemente un captador que devolverá las direcciones NFT contenidas en el contrato inteligente.
  Implemente un captador que devolverá la cantidad de ganancias recaudadas por el administrador.

  En detalle, el contrato inteligente (más tarde: SC) debería tener esta lógica:
  Mensajes
  * AdministradorRetiroBeneficio
   - SC debe verificar que el remitente sea el administrador; de lo contrario, arrojar "privilegios insuficientes"
   - SC debe enviar todas las tarifas cobradas al administrador excepto 0,1 TON (use el mensaje AdminFetchProfit como cuerpo)
     En otras palabras: después de cada operación, el saldo del contrato debe ser igual a 0,1 TON (que están reservadas para almacenamiento) y el resto debe enviarse al administrador.
  * AdminRetiroTodos los NFT
   - SC debe verificar que el valor de tx TON entrante sea suficiente para el retiro de NFT. En concreto, al menos: (1 + totalNftsHeld * 0,08) TONELADAS. De lo contrario, descarte "Fondos insuficientes"
   - SC debe verificar que el remitente sea el administrador; de lo contrario, arrojar "Remitente no válido"
   - Si se pasan todas las comprobaciones, SC debe enviar los NFT uno por uno al administrador
   - SC debería poder retirar todos los NFT con un solo mensaje del administrador
   *PropiedadAsignada
   - si prevOwner es la dirección del propietario (administrador), agregue NFT a la colección
   - si el valor de TON adjunto es inferior a 2,1 TON, detenga la ejecución y devuelva NFT,
     pero solo en caso de que las TON adjuntas sean suficientes para procesar el reembolso sin perder TON en el saldo del SC
   - seleccione aleatoriamente NFT para enviar desde todos los NFT que tiene el contrato inteligente
   - enviar el NFT seleccionado al remitente con todo el saldo restante (excepto las ganancias administrativas = tarifas cobradas de este y otros swaps)
     En otras palabras: el saldo del contrato debería aumentar exactamente 2 TONELADAS, algunas TONELADAS entrantes se consumirán para gas y el resto de las TONELADAS entrantes deberían reembolsarse al remitente.
  
  captadores
  * ganancia
   - devuelve la cantidad de tarifas cobradas que el administrador puede retirar (todas las tarifas menos 0,1 TONELADAS)
  * nft
   - devuelve un dictado de NFT retenidos con índices NFT (números secuenciales desde 0, 1, 2... y hasta 'totalNftsHeld-1') como claves y dirección NFT como valores
     el orden de los NFT en este diccionario no importa
*/
message AdminWithdrawalProfit {
  queryId: Int as uint64;
}

message AdminWithdrawalAllNFTs {
  queryId: Int as uint64;
}

message AdminFetchProfit {
  queryId: Int as uint64;
}

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

contract Task5 with Deployable {
  seed: Int as uint128;
  owner: Address;
  cont: Int;
  total_nft: Int as uint16;
  collection: map<Int as uint16, Address>;
  
  init(seed: Int, owner: Address) {
    self.owner = owner;
    self.seed = seed; // needed to deploy multiple smart contracts copies from one admin address

    self.total_nft = 0;
    self.cont = 0;
  } 

  receive(msg: OwnershipAssigned) {
    if(msg.prevOwner == self.owner){
      self.collection.set(self.total_nft,sender());
      self.total_nft = self.total_nft + 1;
    }
    else{
      if(context().value < ton("2.1") && context().value >= context().readForwardFee()){
        nativeReserve(context().value + ton("2.0"), 3);
        send(SendParameters{
          to: sender(),
          value: 0, 
          mode: 64, 
          bounce: true, 
          body: Transfer{
            queryId: msg.queryId,
            newOwner: msg.prevOwner,
            responseDestination: msg.prevOwner,
            forwardAmount: 0,
            customPayload: null,
            forwardPayload: emptySlice()
          }.toCell()
        });
      }
      else{

        let number: Int = randomInt() % (self.total_nft + 1);
        let nft: Address = sender();
         
        if(number < self.total_nft){
          nft = self.collection.get(number)!!;
          self.collection.set(number,sender());
        }

        send(SendParameters{
          to: nft,
          value: ton("0.1") - context().readForwardFee()*2, 
          mode: 3, 
          bounce: true, 
          body: Transfer{
            queryId: msg.queryId,
            newOwner: msg.prevOwner,
            responseDestination: msg.prevOwner,
            forwardAmount: 0,
            customPayload: null,
            forwardPayload: emptySlice()
          }.toCell()
        });
      }
    }
  }

  receive(msg: AdminWithdrawalProfit) {
    require(sender() == self.owner, "Insufficient privelegies");
    nativeReserve(ton("0.1"), 0);
    
    send(SendParameters{
      to: sender(),
      value: 0, 
      mode: 128, 
      bounce: true, 
      body: AdminFetchProfit {
        queryId: msg.queryId
      }.toCell()
    });
  }

  receive(msg: AdminWithdrawalAllNFTs) {
    require(sender() == self.owner || sender() == myAddress(),"Invalid sender");
    require(context().value >= ton("1") + self.total_nft * ton("0.08"),"Insufficent funds");

    let rep: Int = self.total_nft; 
    if(self.total_nft >= 100){
      rep = 100;
    }

    nativeReserve(context().value, 3);
  
    repeat(rep){   
      send(SendParameters{
        to: self.collection.get(self.cont)!!,
        value: ton("0.08"),
        mode: 2,
        body: Transfer{
          queryId: msg.queryId,
          newOwner: self.owner,
          responseDestination: self.owner,
          forwardAmount: 0,
          customPayload: null,
          forwardPayload: emptySlice()
        }.toCell()
      });
      self.cont = self.cont + 1;
      self.total_nft = self.total_nft - 1;
    }
    if(self.total_nft > 0){
      send(SendParameters{
        to: myAddress(),
        value: 0, 
        mode: 64, 
        bounce: true, 
        body: AdminWithdrawalAllNFTs {
          queryId: msg.queryId
        }.toCell()
      });
    }
    else{
      self.cont = 0;
      self.collection = emptyMap();
      
      // send(SendParameters{
      //   to: self.owner,
      //   value: 0, 
      //   mode: 64, 
      //   bounce: true
      // });
    }

    
  }

  get fun profit(): Int { 
    return myBalance() - ton("0.1");
  }
  
  get fun nfts(): map<Int as uint16, Address> { 
    return self.collection;
  }
}


