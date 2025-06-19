import struct CryptoKit.SymmetricKey
import class Foundation.ProcessInfo
import func SealMessage.file2msg2sealed2stdout
import func SealMessage.secretFile2key

@main
struct msg2sealed {
  static func main() {
    let env: [String: String] = ProcessInfo.processInfo.environment
    let msgFilename: String = env["ENV_IN_MSG_FILENAME"] ?? ""
    let secretFilename: String =
      env["ENV_IN_ONE_TIME_SECRET_FILENAME"] ?? "/run/secrets/key1time"
    let rkey1time: Result<SymmetricKey, _> = secretFile2key(secretFilename)
    guard let key1time = try? rkey1time.get() else {
      print("unable to get the key")
      return
    }

    let wrote: Result<(), Error> = file2msg2sealed2stdout(
      msgFilename,
      oneTimeSecret: key1time,
      limit: 1024,
    )

    do {
      try wrote.get()
    } catch {
      print("unable to write the sealed message.")
    }
  }
}
