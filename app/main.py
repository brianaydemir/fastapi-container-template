import fastapi

app = fastapi.FastAPI()


@app.get("/")
async def read_root():
    return {"Hello": "World"}


@app.get("/headers")
async def read_headers(request: fastapi.Request):
    return request.headers
