# simple-poll Backend

My spouse recently started streaming on twitch and wanted to use polls to interact with chat. Nightbot offers a `!poll` command using [Straw Poll](https://www.strawpoll.me/) as the backend. At some point, the service stopped counting votes, and didn't recover yet.

So I did what I had to do - hack something janky together myself. Feel free to use it as well as you see fit. (In case your Chat does not speak German I'd suggest you adjust the aswers of the `twitch-*` functions though.)

To replace the default `!poll` command, deactivate the default Nightbot command add these custom ones, mind the `<placeholders>`:

| Command | Message                                                                                                                                                                                    |
| ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `!poll` | `$(eval const api = $(urlfetch json https://<your-function-app-name>.azurewebsites.net/api/twitch-poll?code=<your-function-key>&command=$(querystring)); api['message'])`                  |
| `!vote` | `Thanks $(user)! $(eval const api = $(urlfetch json https://<your-function-app-name>.azurewebsites.net/api/twitch-vote?code=<your-function-key>&optionId=$(querystring)); api['message'])` |

## But I don't have an Azure Subscription!

It is possible to host Function Apps and an emulated Storage Account yourself hosting containers. This will likely need some adjustments, but I believe in you.
