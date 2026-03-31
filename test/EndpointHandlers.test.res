open Test
open TestUtils

describe("Endpoint handlers", () => {
  testAsync("prefixing of endpoint routes work", async () => {
    let _handler = Handler.testHandler.endpointGet(
      "/endpoint-test",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let response = await getResponse(
      ~getContent=_ => {
        Hjsx.string("nope")
      },
      ~url="/_api/endpoint-test",
    )

    let text = await response->Response.text

    expect(text)->Expect.toBe("Test!")
  })

  testAsync("security policy can block endpoint responses", async () => {
    let _handler = Handler.testHandler.endpointGet(
      "/endpoint-test-block",
      ~securityPolicy=async _ =>
        SecurityPolicy.Block({
          code: Some(403),
          message: Some("Forbidden"),
        }),
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let response = await getResponse(~url="/_api/endpoint-test-block")

    let text = await response->Response.text

    expect(text)->Expect.toBe("Forbidden")
    expect(response->Response.status)->Expect.toBe(403)
  })

  testAsync("security policy metadata is forwarded to endpoint handlers", async () => {
    let _handler = Handler.testHandler.endpointGet(
      "/endpoint-test-meta",
      ~securityPolicy=async _ => SecurityPolicy.Allow("meta"),
      ~handler=async ({securityPolicyData}) => {
        Response.make(securityPolicyData)
      },
    )
    let response = await getResponse(~url="/_api/endpoint-test-meta")

    let text = await response->Response.text

    expect(text)->Expect.toBe("meta")
  })

  testAsync("duplicate endpoint registrations keep the first handler", async () => {
    let _firstHandler = Handler.testHandler.endpointGet(
      "/endpoint-test-duplicate-first-wins",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("First")
      },
    )
    let _secondHandler = Handler.testHandler.endpointGet(
      "/endpoint-test-duplicate-first-wins",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Second")
      },
    )
    let response = await getResponse(~url="/_api/endpoint-test-duplicate-first-wins")

    let text = await response->Response.text

    expect(text)->Expect.toBe("First")
  })

  testAsync("direct POST, PUT, DELETE, and PATCH endpoint registration works", async () => {
    let _postHandler = Handler.testHandler.endpointPost(
      "/endpoint-test-post-direct",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("POST direct")
      },
    )
    let _putHandler = Handler.testHandler.endpointPut(
      "/endpoint-test-put-direct",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("PUT direct")
      },
    )
    let _deleteHandler = Handler.testHandler.endpointDelete(
      "/endpoint-test-delete-direct",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("DELETE direct")
      },
    )
    let _patchHandler = Handler.testHandler.endpointPatch(
      "/endpoint-test-patch-direct",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("PATCH direct")
      },
    )

    let postResponse = await getResponse(~method=POST, ~url="/_api/endpoint-test-post-direct")
    let putResponse = await getResponse(~method=PUT, ~url="/_api/endpoint-test-put-direct")
    let deleteResponse = await getResponse(
      ~method=DELETE,
      ~url="/_api/endpoint-test-delete-direct",
    )
    let patchResponse = await getResponse(~method=PATCH, ~url="/_api/endpoint-test-patch-direct")

    let postText = await postResponse->Response.text
    let putText = await putResponse->Response.text
    let deleteText = await deleteResponse->Response.text
    let patchText = await patchResponse->Response.text

    expect(postText)->Expect.toBe("POST direct")
    expect(putText)->Expect.toBe("PUT direct")
    expect(deleteText)->Expect.toBe("DELETE direct")
    expect(patchText)->Expect.toBe("PATCH direct")
  })

  testAsync("delaying endpoint implementations works", async () => {
    let getHandler = Handler.testHandler.endpointGetRef("/endpoint-test-delay-get")
    let postHandler = Handler.testHandler.endpointPostRef("/endpoint-test-delay-post")
    let putHandler = Handler.testHandler.endpointPutRef("/endpoint-test-delay-put")
    let deleteHandler = Handler.testHandler.endpointDeleteRef("/endpoint-test-delay-delete")
    let patchHandler = Handler.testHandler.endpointPatchRef("/endpoint-test-delay-patch")

    Handler.testHandler.endpointGetDefine(
      getHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("GET delayed")
      },
    )
    Handler.testHandler.endpointPostDefine(
      postHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("POST delayed")
      },
    )
    Handler.testHandler.endpointPutDefine(
      putHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("PUT delayed")
      },
    )
    Handler.testHandler.endpointDeleteDefine(
      deleteHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("DELETE delayed")
      },
    )
    Handler.testHandler.endpointPatchDefine(
      patchHandler,
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("PATCH delayed")
      },
    )

    let getResponseResult = await getResponse(~url="/_api/endpoint-test-delay-get")
    let postResponse = await getResponse(~method=POST, ~url="/_api/endpoint-test-delay-post")
    let putResponse = await getResponse(~method=PUT, ~url="/_api/endpoint-test-delay-put")
    let deleteResponse = await getResponse(
      ~method=DELETE,
      ~url="/_api/endpoint-test-delay-delete",
    )
    let patchResponse = await getResponse(~method=PATCH, ~url="/_api/endpoint-test-delay-patch")

    let getText = await getResponseResult->Response.text
    let postText = await postResponse->Response.text
    let putText = await putResponse->Response.text
    let deleteText = await deleteResponse->Response.text
    let patchText = await patchResponse->Response.text

    expect(getText)->Expect.toBe("GET delayed")
    expect(postText)->Expect.toBe("POST delayed")
    expect(putText)->Expect.toBe("PUT delayed")
    expect(deleteText)->Expect.toBe("DELETE delayed")
    expect(patchText)->Expect.toBe("PATCH delayed")
  })

  testAsync("endpoint URL helpers return the correct URLs", async () => {
    let getHandler = Handler.testHandler.endpointGet(
      "/endpoint-test-url-get",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let postHandler = Handler.testHandler.endpointPost(
      "/endpoint-test-url-post",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let putHandler = Handler.testHandler.endpointPut(
      "/endpoint-test-url-put",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let deleteHandler = Handler.testHandler.endpointDelete(
      "/endpoint-test-url-delete",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )
    let patchHandler = Handler.testHandler.endpointPatch(
      "/endpoint-test-url-patch",
      ~securityPolicy=SecurityPolicy.allow,
      ~handler=async _ => {
        Response.make("Test!")
      },
    )

    expect(getHandler->Handlers.endpointGetToEndpointURL)->Expect.toBe("/_api/endpoint-test-url-get")
    expect(postHandler->Handlers.endpointPostToEndpointURL)->Expect.toBe("/_api/endpoint-test-url-post")
    expect(putHandler->Handlers.endpointPutToEndpointURL)->Expect.toBe("/_api/endpoint-test-url-put")
    expect(deleteHandler->Handlers.endpointDeleteToEndpointURL)->Expect.toBe("/_api/endpoint-test-url-delete")
    expect(patchHandler->Handlers.endpointPatchToEndpointURL)->Expect.toBe("/_api/endpoint-test-url-patch")
  })
})
