---
title: "json.RawMessageでGo APIのJSONを安全に検証・統合する"
emoji: "🛡️"
type: "tech"
topics: ["go", "json", "api"]
published: true
---

I recently built an API where the user sends a JSON value in one of the fields. The requirement was to log invalid JSON errors but let the rest of the data continue through the system's normal flow.

It was also important that, if the received JSON was valid, it would be integrated seamlessly into the API responses. Since the JSON could vary and I didn't know its structure, I used `json.RawMessage` as the field type. That way, when calling `json.Marshal`, the data is correctly embedded into the main JSON.

The problem arises if the user sends invalid JSON. That can easily break the system. You should never trust user input, especially in cases like this.

## Validating JSON

Fortunately, the Go standard library has a function to validate JSON. See the example below.

```golang
// Intentionally invalid JSON
j := []byte(`{"name":"John" "age":30}`)

if json.Valid(j) {
    println("JSON valido")
    return
}
println("JSON inválido")
```

This way, I can validate the JSON sent by the user before integrating it into the system. If the JSON is invalid, I replace it with `nil`. So when I turn the struct into a byte array with `json.Marshal`, the field with the user's data is ignored, avoiding failures in the JSON parser.

To illustrate, I wrote the example below:

```golang
// Intentionally invalid JSON.
j := []byte(`{"name":"John" "age":30}`)

// System struct that receives valid data and a field
// with JSON coming from the user that we don't control.
s := struct {
    ClientID     string          `json:"client_id"`
    ExternalData json.RawMessage `json:"external_data,omitempty"`
}{
    ClientID:     "123",
    ExternalData: j,
}

// If the JSON coming from the user is invalid
// I set the field to nil so Marshal doesn't fail.
// In the original program I would also log this error.
if !json.Valid(s.ExternalData) {
    s.ExternalData = nil
}

// Finally we use the Marshal function to
// generate the byte array with the struct
// combining our data and the JSON coming from the user.
b, _ := json.MarshalIndent(s, "", "    ")
println(string(b))
```

The output of this code with the invalid JSON omits the *ExternalData* field.

```json
{
    "client_id": "123"
}
```

If the data is valid, it is integrated into the struct without any problems.

To make the JSON valid, just add the missing comma:

```golang
j := []byte(`{"name":"John", "age":30}`)
```

The output will be the following:

```json
{
    "client_id": "123",
    "external_data": {
        "name": "John",
        "age": 30
    }
}
```

## Testing other formats

So far, the output is formatted correctly because the `ExternalData` field is of type `json.RawMessage`. See what happens if this field is of type string.

```json
{
  "client_id": "123",
  "external_data": "{"name":"John", "age":30}"
}
```

Notice that the `ExternalData` field is now a string containing the JSON with escaped quotes, instead of integrating the JSON into the original struct. If I used a byte array instead of a string, the content of `ExternalData` would be converted to *base64*.

```json
{
  "client_id": "123",
  "external_data": "eyJuYW1lIjoiSm9obiIsICJhZ2UiOjMwfQ=="
}
```

Remember: the functions in the `json` package convert byte arrays to *base64*.

To test, we can pipe the output through the `base64` utility and check whether we get the correct string at the end.

```bash
echo "eyJuYW1lIjoiSm9obiIsICJhZ2UiOjMwfQ==" | base64 -D
```

Returns:

```
{"name":"John","age":30}
```

## Conclusion

To build a robust API, we can't trust the data provided by the user. Everything must be checked, even in cases where we don't know the exact structure. It's important to explore the language's features, such as data types and validation functions. With care, we meet the requirements, handle possible errors properly, and keep the system running continuously.

Video with an explanation of the code.

@[youtube](YzLULahfn3U)

