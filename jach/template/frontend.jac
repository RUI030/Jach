"""Client UI, built from the jac-shadcn components in components/ui."""

import from server { ping }
import from .components.ui.button { Button }
import from .components.ui.card { Card, CardHeader, CardTitle, CardDescription, CardContent }

"""Show the page: a Ping button and the reply from the server."""
def:pub app -> JsxElement {
    has reply: str = "";

    async def onPing {
        reply = await ping();
    }

    <div className="min-h-screen bg-background text-foreground flex items-start justify-center p-6">
        <Card className="w-full max-w-md">
            <CardHeader>
                <CardTitle>App</CardTitle>
                <CardDescription>Press Ping to call the server.</CardDescription>
            </CardHeader>
            <CardContent className="flex items-center gap-3">
                <Button onClick={onPing}>Ping</Button>
                <p>{reply}</p>
            </CardContent>
        </Card>
    </div>
}
