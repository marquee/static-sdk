# Content API

## Error Responses

### 201 CREATED

The requested resource has been created. This is considered an error response
by the Static SDK, which is for _read-only_ projects and MUST NOT create
objects. The SDK guards against using tokens with write-access permissions, so
requests that would result in this response code should never be initiated.

### 204 NO CONTENT

The requested resource has been modified or deleted. This is considered an
error response by the Static SDK, which is for _read-only_ projects and MUST
NOT modify or delete objects. The SDK guards against using tokens with
write-access permissions, so requests that would result in this response code
should never be initiated.

### 401 UNAUTHORIZED

An access token was not included in the request, perhaps because it is not
set in the `package.json`. See [configuration/tokens](./configuration/#tokens).

All requests to the Marquee Content API MUST be authenticated. API tokens MUST
be specified using either the `Authorization` header or a `?token` parameter:

    Authorization: Token <token>
    ?token=<token>

### 403 FORBIDDEN

The access token specified in `package.json` does not have permission to act
on the requested content object.

This is an uncommon error in the Marquee Content API as we practice
[non-acknowledgement][rfc2616] to avoid disclosing a resource even exists to
unauthorized clients. Typically, a 404 will be returned whenever a 403 would
be expected.

Note: S3 has the opposite behavior, returning 403 when a client might expect
a 404. It has the same effect, and is arguably more semantic, but often
confusing.

### 404 NOT FOUND

The specified content object does not exist. (Or the token does not have read-
access permission for the publication. See [_403 FORBIDDEN_](./#403-forbidden).)

### 410 GONE

The specified content object was previously deleted.

### 500 Internal Server Error

There was a problem with the Content API. Try the request again. If requests
continue to return 500s, contact [developers@marquee.by](mailto:developers@marquee.by).


[rfc2616]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.4.4