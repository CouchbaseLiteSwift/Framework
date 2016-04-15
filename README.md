# CouchbaseLiteSwift

## A Swift wrapper for the Couchbase Lite iOS library.

This library is a Swift wrapper for the [couchbase-lite-ios API](https://github.com/couchbase/couchbase-lite-ios) to make your life easier.

Here are some brief examples of what it can do for you:

### Add new models to the database

```
try User.create([
"givenName": "Bibi",
"familyName": "Blocksberg",
"age": 14
]).save()
```

### Easy Querying

```
for user in CLSQuery<User>().conditions("givenName != '' AND familyName != ''"){
print( user.familyName )
}
```

### Complex Querying

```
for user in CLSQuery<User>().conditions([
"givenName != ''",
"AND familyName != ''",
"AND (",
"age < 18",
"OR age > 50",
")"])
.sort("familyName", order: .DESC){

print("\(user.givenName) \(user.familyName)")
}
```

### Delete models from the database

```
try CLSQuery<User>().conditions("familyName = 'Betschart‘").deleteDocuments()
```

## More to come!
Documentation is work in progress. Feel free to scan the code directly to get a deeper look.
** Tip: Start with the CouchbaseLiteSwift/ViewController.swift **

# CouchbaseLiteSwift API

The CouchbaseLiteSwift API mainly consists of three easy to use classes: Query, AnyModel and AnyAttachment.

## CLSQuery

An easy wrapper for the Couchbase Lite QueryBuilder API. It takes care of caching, enumerating and filtering all of your AnyModels.

## CLSModel

A generic subclass of the Couchbase Lite CBLModel with additional, Swift like functionalities. You should make sure, your models are subclassing this one like follows:

```
@objc(User)
class User: CLSModel{
@NSManaged var givenName: String?
@NSManaged var familyName: String?
}
```

## CLSAttachment

A helper class, which allows you to enrich regular file attachments with meta data.
You are able to receive and set all attachments `[AnyAttachment]?` by using the AnyModel.attachments property.