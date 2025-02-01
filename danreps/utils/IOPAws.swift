//
//  IOPAws.swift
//  MacLab
//
//  Created by Daniel Francis on 1/4/25.
//
import AWSS3

struct IOPAws {
    var _app = "Base"
    let _bucketName = "df-2021"
    init(app:String) {
        _app = app
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: AwsStash.AccessKey, secretKey: AwsStash.SecretKey)
        let configuration = AWSServiceConfiguration(region: .USEast1, credentialsProvider: credentialsProvider)

        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    public func Read(dir: String, file: String) async -> String
    {
        // Data\Dint\file
        let keyName = dir + "/" + _app + "/" + file
        
        return await getObjectAsync(keyName: keyName)
    }
    
    public func Write(dir: String, file: String, content: String) async -> Bool
    {
        let keyName = dir + "/" + _app + "/" + file
  
        return (await setObjectAsync(keyName: keyName, content: content) == nil)
    }
    func setObjectAsync(keyName: String, content: String) async -> String? {
   
        return await withCheckedContinuation { continuation in
            setText(keyName: keyName, content: content) { result in
                continuation.resume(returning: result)
            }
        }
    }
    func getObjectAsync(keyName: String) async -> String {
   
        return await withCheckedContinuation { continuation in
            getText(keyName: keyName) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func getText(keyName: String, completion: @escaping (String) -> Void)
    {
        let s3 = AWSS3.default()
        let request = AWSS3GetObjectRequest()
        request?.bucket = _bucketName
        request?.key = keyName
        
        s3.getObject(request!) { response, error in
            if let error = error {
                print("Error reading from S3: \(error)")
                completion("")
            } else if let body = response?.body as? Data,
                      let content = String(data: body, encoding: .utf8) {
                //print("File content: \(content)")
                completion(content)
            } else {
                print("Failed to retrieve content.")
                completion("")
            }
        }
    }
    func setText(keyName: String, content: String, completion: @escaping (String?) -> Void) {
        //let data = "Hello, AWS S3! hi 1/6".data(using: .utf8)!
        guard let data = content.data(using: .utf8) else {
            completion("Failed to encode content as UTF-8")
            return
        }
        
        let putRequest = AWSS3PutObjectRequest()!
        putRequest.bucket = _bucketName
        putRequest.key = keyName
        putRequest.body = data as NSData
        putRequest.contentType = "plain/text" //"application/json"
        putRequest.contentLength = (data.count) as NSNumber
        
        AWSS3.default().putObject(putRequest).continueWith { task -> Any? in
            if let error = task.error {
                print("Failed to upload: \(error.localizedDescription)")
                completion(error.localizedDescription)
            } else {
                print("Upload successful")
                completion(nil)
            }
            return nil
        }
    }
    func setObject(keyName: String, completion: @escaping (String) -> Void)
    {
        let s3 = AWSS3.default()
        let request = AWSS3GetObjectRequest()
        request?.bucket = _bucketName
        request?.key = keyName
        
        s3.getObject(request!) { response, error in
            if let error = error {
                print("Error reading from S3: \(error)")
                completion("")
            } else if let body = response?.body as? Data,
                      let content = String(data: body, encoding: .utf8) {
                //print("File content: \(content)")
                completion(content)
            } else {
                print("Failed to retrieve content.")
                completion("")
            }
        }
    }
    
    static func ChangeOwner(owner: String){
        UserDefaults.standard.set(owner, forKey: "Owner")
    }
    static func GetOwner() -> String{
        return UserDefaults.standard.string(forKey: "Owner") ?? "Dan"
    }
    
    public func Test()
    {
        //configureAWS()
        let s3 = AWSS3.default()
        let bucketName = "df-2021"
        let keyName = "test.txt"
        
        let request = AWSS3GetObjectRequest()
        request?.bucket = bucketName
        request?.key = keyName
        
        s3.getObject(request!) { response, error in
            if let error = error {
                print("Error reading from S3: \(error)")
            } else if let body = response?.body as? Data,
                      let content = String(data: body, encoding: .utf8) {
                print("File content: \(content)")
            } else {
                print("Failed to retrieve content.")
            }
        }
    }
}
