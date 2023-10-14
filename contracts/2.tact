import "@stdlib/deploy";

/*
  TASK 2 - Proxy contract 
  Create a contract that forwards all messages sent and tokens received 
  to the admin contract (the address will be set in init_store).
  Transaction from proxy contract to admin contrac should contain
    - Address, of ueser who sended trx (should be stored in the body cell).
    - Original message that proxy smart contract recived from user (should be stored in the first ref in the outcoming body).
  Also, if admin contract will bounce message (Bounced / opcode 0x44), then you need to send all ton`s back to user.
  User address will be given in bounced msg body as "sender".
*/

/*
  TAREA 2 - Contrato de representación
  Cree un contrato que reenvíe todos los mensajes enviados y los tokens recibidos.
  al contrato de administrador (la dirección se establecerá en init_store).
  La transacción del contrato de representación al contrato de administración debe contener
    - Dirección del usuario que envió trx (debe almacenarse en la celda del cuerpo).
    - Mensaje original que el contrato inteligente de proxy recibió del usuario (debe almacenarse en la primera referencia del cuerpo saliente).
  Además, si el contrato de administrador rebota el mensaje (Rebotado/código de operación 0x44), entonces debe enviar todos los toneladas al usuario.
  La dirección del usuario se proporcionará en el cuerpo del mensaje devuelto como "remitente".
*/

message(0x44) Bounced {
  queryId: Int as uint64;
  sender: Address;
}

contract Task2 with Deployable {
  admin: Address;

  init(admin: Address) {
    self.admin = admin;
  }
  
  receive(msg: Bounced) {
    
  }

  receive(msg: Slice) {
    let sender: Address = sender();
    let data = beginCell();
    data.storeAddress(sender);
    data.storeRef(msg);

    let body: Cell = data.endCell();
    

    send(SendParameters{
      to: self.admin, 
      mode: SendIgnoreErrors, 
      bounce: true,
      body: body
    });
  }
}

