import enum CryptoKit.AES
import struct CryptoKit.SymmetricKey
import struct CryptoKit.SymmetricKeySize
import struct Foundation.Data
import protocol Foundation.DataProtocol
import class Foundation.FileHandle
import class Foundation.FileManager
import struct Foundation.URL

/// Seals the message using a random nonce.
public func sealOnce(
  _ plainMessage: Data,
  oneTimeSecret: SymmetricKey,
) -> Result<AES.GCM.SealedBox, Error> {
  Result(catching: {
    try AES.GCM.seal(
      plainMessage,
      using: oneTimeSecret,
      nonce: nil,  // random nonce will be used
    )
  })
}

/// Opens the sealed box.
public func open(
  _ sealed: AES.GCM.SealedBox,
  oneTimeSecret: SymmetricKey,
) -> Result<Data, Error> {
  Result(catching: {
    try AES.GCM.open(
      sealed,
      using: oneTimeSecret,
    )
  })
}

/// Opens the combined data using the specified key.
///
/// - Parameters:
///   - sealedMessage: The combined data(nonce + encrypted + authn tag).
///   - oneTimeSecret: The secret expected to be used once.
public func open(
  _ sealedMessage: Data,
  oneTimeSecret: SymmetricKey,
) -> Result<Data, Error> {
  let rsealed: Result<AES.GCM.SealedBox, _> = Result(catching: {
    try AES.GCM.SealedBox(combined: sealedMessage)
  })
  return rsealed.flatMap {
    let sealed: AES.GCM.SealedBox = $0
    return open(
      sealed,
      oneTimeSecret: oneTimeSecret,
    )
  }
}

/// Opens the sealed box(nonce+encrypted+tag).
public func open(
  nonce: AES.GCM.Nonce,
  encrypted: Data,
  atag: Data,
  oneTimeSecret: SymmetricKey,
) -> Result<Data, Error> {
  let rsealed: Result<AES.GCM.SealedBox, _> = Result(catching: {
    try AES.GCM.SealedBox(
      nonce: nonce,
      ciphertext: encrypted,
      tag: atag,
    )
  })
  return rsealed.flatMap {
    let sealed: AES.GCM.SealedBox = $0
    return open(
      sealed,
      oneTimeSecret: oneTimeSecret,
    )
  }
}

/// Reads the sealed message and prints the opend message.
public func stdin2sealed2opened2stdout(
  sealedSize: Int,
  oneTimeSecret: SymmetricKey,
  input: FileHandle = .standardInput,
  output: FileHandle = .standardOutput,
) -> Result<(), Error> {
  let sealed: Data = input.readData(ofLength: sealedSize)
  let ropened: Result<Data, _> = open(
    sealed,
    oneTimeSecret: oneTimeSecret,
  )
  return ropened.flatMap {
    let opened: Data = $0
    return Result(catching: {
      try output.write(contentsOf: opened)
    })
  }
}

/// Reads the message and prints the sealed message.
public func stdin2msg2sealed2stdout(
  msgSize: Int,
  oneTimeSecret: SymmetricKey,
  input: FileHandle = .standardInput,
  output: FileHandle = .standardOutput,
) -> Result<(), Error> {
  let msg: Data = input.readData(ofLength: msgSize)
  let rsealed: Result<AES.GCM.SealedBox, _> = sealOnce(
    msg,
    oneTimeSecret: oneTimeSecret,
  )
  return rsealed.flatMap {
    let sealed: AES.GCM.SealedBox = $0
    let combined: Data = sealed.combined ?? Data()
    return Result(catching: {
      try output.write(contentsOf: combined)
    })
  }
}

/// Gets the data from the file.
public func file2data(
  _ file: FileHandle,
  count: Int,
) -> Result<Data, Error> {
  Result(catching: { try file.read(upToCount: count) ?? Data() })
}

/// Gets the data from the specified file.
public func filename2data(
  _ inputFilename: String,
  fileManager: FileManager = .default,
  limit: Int = 1_048_576,
) -> Result<Data, Error> {
  let rattr: Result<[_: Any], _> = Result(catching: {
    try fileManager.attributesOfItem(atPath: inputFilename)
  })
  let oattr: [_: Any]? = try? rattr.get()
  let attr: [_: Any] = oattr ?? [:]
  let oasize: Any? = attr[.size]
  let osize: UInt64? = oasize as? UInt64
  let size: UInt64 = osize ?? 0
  let isize: Int = Int(size)
  let msize: Int = min(limit, isize)

  let ofile: FileHandle? = FileHandle(forReadingAtPath: inputFilename)
  return
    ofile.map {
      let hndl: FileHandle = $0
      defer {
        try? hndl.close()
      }
      return file2data(hndl, count: msize)
    } ?? .success(Data())
}

/// Reads the sealed message from the file and prints the opened message.
public func file2sealed2opened2stdout(
  _ inputFilename: String,
  oneTimeSecret: SymmetricKey,
  fileManager: FileManager = .default,
  limit: Int = 1_048_576,
  output: FileHandle = .standardOutput,
) -> Result<(), Error> {
  let rdata: Result<Data, _> = filename2data(
    inputFilename,
    fileManager: fileManager,
    limit: limit,
  )
  let osealed: Data? = try? rdata.get()
  let sealed: Data = osealed ?? Data()
  let opened: Result<Data, _> = open(
    sealed,
    oneTimeSecret: oneTimeSecret,
  )
  return opened.flatMap {
    let dat: Data = $0
    return Result(catching: { try output.write(contentsOf: dat) })
  }
}

/// Reads the message from the file and prints the sealed message.
public func file2msg2sealed2stdout(
  _ inputFilename: String,
  oneTimeSecret: SymmetricKey,
  fileManager: FileManager = .default,
  limit: Int = 1_048_576,
  output: FileHandle = .standardOutput,
) -> Result<(), Error> {
  let rdata: Result<Data, _> = filename2data(
    inputFilename,
    fileManager: fileManager,
    limit: limit,
  )
  let omsg: Data? = try? rdata.get()
  let msg: Data = omsg ?? Data()
  let sealed: Result<AES.GCM.SealedBox, _> = sealOnce(
    msg,
    oneTimeSecret: oneTimeSecret,
  )
  return sealed.flatMap {
    let dat: Data = $0.combined ?? Data()
    return Result(catching: { try output.write(contentsOf: dat) })
  }
}

/// Gets the symmetric key from the file.
public func secretFile2key(
  _ secret: FileHandle,
  fileSize: Int = 32,
) -> Result<SymmetricKey, Error> {
  let rdat: Result<Data, _> = Result(catching: {
    try secret.read(upToCount: fileSize) ?? Data()
  })
  return rdat.map { SymmetricKey(data: $0) }
}

/// Gets the symmetric key from the specified file.
public func secretFile2key(
  _ secretFilename: String,
  fileSize: Int = 32,
) -> Result<SymmetricKey, Error> {
  let ofile: FileHandle? = FileHandle(forReadingAtPath: secretFilename)
  let rdata: Result<Data, _> =
    ofile.map {
      let file: FileHandle = $0
      defer { try? file.close() }
      return file2data(file, count: fileSize)
    } ?? .success(Data())
  return rdata.map { SymmetricKey(data: $0) }
}
