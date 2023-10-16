import "@stdlib/deploy";
/*
  TAREA 3 - DEX
  Cree un contrato jetton dex simple que intercambie un par de jettons: A y B.
  El precio de los jettons depende de la cantidad de jettons que tenga el contrato inteligente.
  Por lo tanto, el contrato inteligente debe realizar un seguimiento de la cantidad de jettons que tiene.
  
  El precio del jetton A en el swap B->A debe calcularse mediante la fórmula "cantidadDeJettonAOnContract * decimal / cantidadDeJettonBOnContract".
  Los precios de los tokens deben estar decimalizados para mayor precisión, por lo que son los precios los que deben ajustarse al decimal 1e9.
  Los decimales sólo son necesarios para la precisión del precio. Debe configurarse como 1e9.
  Entonces, si el contrato inteligente tiene 10 de jetton A y 2 de jetton B, luego de enviar 1 jetton B debería recibir 5 de jetton A.

  La fórmula de ejemplo para la cantidad de AJettonToSend en el intercambio B->A será
  (cantidadDeJettonAOnContract * decimal / cantidadDeJettonBOnContract) * cantidadOfTokenBToSwap / decimal

  Si el grupo de contratos inteligentes no tiene suficientes jettons para negociar,
  entonces debería enviar los jettons entrantes al usuario. Para una explicación más clara,
  Veamos el ejemplo que describimos anteriormente (el contrato inteligente tiene 10 de Jetton A y 2 de Jetton B).
  Si el usuario envía 3 jettons B, el contrato inteligente debería rechazar el mensaje (porque el contrato no tiene 3 * 5 = 15 jettons A)
  y enviar 3 jettons B de regreso al usuario.

  Si el contrato inteligente recibe un jetton diferente (ni A ni B), se produce un error.

  Implemente un captador que devuelva el número de jettons en el grupo y
  uno más para obtener el precio del jetton A o del jetton B.
  Comportamiento de los captadores con parámetro incorrecto (dirección distinta a la del jetton A o B)
  no está definido (no existen tales pruebas).
  
  Nota:
  El administrador puede agregar jettons A y B simplemente enviándolos al contrato inteligente (necesitamos agregar el suministro inicial al grupo para que sea funcional).
  Para ser exactos: cualquier jetton (A o B) recibido del administrador se "agrega". El administrador no puede intercambiar.
 */

message(0x7362d09c) TokenNotification {
    queryId: Int as uint64;
    amount: Int as coins;
    from: Address;
    forwardPayload: Slice as remaining;
}

message(0xf8a7ea5) TokenTransfer {
    queryId: Int as uint64;
    amount: Int as coins;
    destination: Address;
    responseDestination: Address?;
    customPayload: Cell?;
    forwardTonAmount: Int as coins;
    forwardPayload: Slice as remaining;
}

contract Task3 with Deployable {
  owner: Address;
  aAmount: Int;
  bAmount: Int;
  jettonAddressA: Address;
  jettonAddressB: Address;
  decimal: Int;

  init(admin: Address, newJettonAddressA: Address, newJettonAddressB: Address) {
    self.owner = admin;
    self.jettonAddressA = newJettonAddressA;
    self.jettonAddressB = newJettonAddressB;
    self.aAmount = 0;
    self.bAmount = 0;
    self.decimal = 1000000000;
  }

  receive(msg: TokenNotification) {
    if(msg.from == self.owner){
      if(sender() == self.jettonAddressA){
        self.aAmount = self.aAmount + msg.amount;
      }
      if(sender() == self.jettonAddressB){
        self.bAmount = self.bAmount + msg.amount;
      }
    }
    else{
      if(sender() != self.jettonAddressA && sender() != self.jettonAddressB){
        throw(132);
      }

      if(sender() == self.jettonAddressB){
        let send_amount: Int =  (self.aAmount * self.decimal / self.bAmount) * msg.amount / self.decimal;

        if(send_amount > self.aAmount){
          send(SendParameters{
            to: msg.from,
            value: 0, 
            mode: SendIgnoreErrors, 
            bounce: true, 
            body: TokenTransfer{
              queryId: msg.queryId,
              amount: msg.amount,
              destination: self.jettonAddressA,
              forwardTonAmount: 0,
              forwardPayload: msg.forwardPayload
            }
          });
        }
        else{
          send(SendParameters{
            to: msg.from,
            value: 0, 
            mode: SendIgnoreErrors, 
            bounce: true, 
            body: TokenTransfer{
              queryId: msg.queryId,
              amount: send_amount,
              destination: self.jettonAddressB,
              forwardTonAmount: 0,
              forwardPayload: msg.forwardPayload
            }
          });
        }
      if(sender() == self.jettonAddressA){
        let send_amount: Int =  (self.bAmount * self.decimal / self.aAmount) * msg.amount / self.decimal;

        if(send_amount > self.bAmount){
          send(SendParameters{
            to: msg.from,
            value: 0, 
            mode: SendIgnoreErrors, 
            bounce: true, 
            body: TokenTransfer{
              queryId: msg.queryId,
              amount: msg.amount,
              destination: self.jettonAddressB,
              forwardTonAmount: 0,
              forwardPayload: msg.forwardPayload
            }
          });
        }
        else{
          send(SendParameters{
            to: msg.from,
            value: 0, 
            mode: SendIgnoreErrors, 
            bounce: true, 
            body: TokenTransfer{
              queryId: msg.queryId,
              amount: send_amount,
              destination: self.jettonAddressA,
              forwardTonAmount: 0,
              forwardPayload: msg.forwardPayload
            }
          });
        }
      }
    }
  } 
  get fun price(jetton: Address): Int { 

    if(jetton == self.jettonAddressA){
      return (self.aAmount * self.decimal / self.bAmount);
    }
    else{
      return (self.bAmount * self.decimal / self.aAmount);
    }
  }
  
  get fun balance(jetton: Address): Int {

    if(jetton == self.jettonAddressA){
      return self.aAmount;
    }
    else{
      return self.bAmount;
    }
  }
}