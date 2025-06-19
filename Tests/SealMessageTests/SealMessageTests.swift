import Testing

import enum CryptoKit.AES
import struct CryptoKit.SymmetricKey
import struct Foundation.Data

@testable import func SealMessage.open
@testable import func SealMessage.sealOnce

@Suite("Seal and Open")
struct SealMsgTests {

  @Test("Opens the sealed box")
  func testOpen() throws {
    let key: SymmetricKey = SymmetricKey(size: .bits256)
    let msg: String = "helo,wrld"

    let odat: Data? = msg.data(using: .utf8)
    let dat: Data = odat ?? Data()

    let rsealed: Result<AES.GCM.SealedBox, _> = sealOnce(
      dat,
      oneTimeSecret: key,
    )
    let sealed: AES.GCM.SealedBox = try rsealed.get()

    let ropened: Result<Data, _> = open(sealed, oneTimeSecret: key)
    let opened: Data = try ropened.get()
    #expect(opened == dat)
  }

  @Test("Opens pair with tag")
  func testOpenTaggedPair() throws {
    let key: SymmetricKey = SymmetricKey(size: .bits256)
    let msg: String = "hello,world"

    let odat: Data? = msg.data(using: .utf8)
    let dat: Data = odat ?? Data()

    let rsealed: Result<AES.GCM.SealedBox, _> = sealOnce(
      dat,
      oneTimeSecret: key,
    )
    let sealed: AES.GCM.SealedBox = try rsealed.get()

    let nonce: AES.GCM.Nonce = sealed.nonce
    let ciphertext: Data = sealed.ciphertext
    let tag: Data = sealed.tag

    let ropened: Result<Data, _> = open(
      nonce: nonce,
      encrypted: ciphertext,
      atag: tag,
      oneTimeSecret: key,
    )
    let opened: Data = try ropened.get()
    #expect(opened == dat)
  }

  @Test("Opens combined data")
  func testOpenCombined() throws {
    let key: SymmetricKey = SymmetricKey(size: .bits256)
    let msg: String = "hello,world"

    let odat: Data? = msg.data(using: .utf8)
    let dat: Data = odat ?? Data()

    let rsealed: Result<AES.GCM.SealedBox, _> = sealOnce(
      dat,
      oneTimeSecret: key,
    )
    let sealed: AES.GCM.SealedBox = try rsealed.get()

    let combined: Data = sealed.combined ?? Data()

    let ropened: Result<Data, _> = open(
      combined,
      oneTimeSecret: key,
    )
    let opened: Data = try ropened.get()
    #expect(opened == dat)
  }

}
