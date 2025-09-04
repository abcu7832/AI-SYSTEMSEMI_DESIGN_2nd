# AXI protocol
### The AXI Protocol is a point-to-point specification, not a bus specification.

## AXI CHANNELS
```
Write Address(AW)
Write Data(W)
Write Response(B)
Read Address(AR)
Read Data(R)
```
Write operations use the following channels:

* The master sends an address on the Write Address (AW) channel and transfers data on the Write Data (W) channel to the slave.

* The slave writes the received data to the specified address. Once the slave has completed the write operation, it responds with a message to the master on the Write Response (B) channel.

Read operations use the following channels:

* The master sends the address it wants to read on the Read Address (AR) channel.

* The slave sends the data from the requested address to the master on the Read Data (R) channel.

* The slave can also return an error message on the Read Data (R) channel. An error occurs if, for example, the address is not valid, or the data is corrupted, or the access does not have the right security permission.

### Read sequence can happen at the same time as a write sequence 

## Channel transfers and transactions
----
### Channel handshake

![250904_handshake](/images/250904_handshake.png)

![250904_channel_src_dst](/images/250904_channel_src_dst.png)
