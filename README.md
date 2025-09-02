Steps to reproduce:

1. Check out project.
2. Run app.
3. Take an NFC tag with an NDEF message on it (can be any URL) and read it.
4. The app displays the message.
5. Go to the CoreNFCPackage and go to line 240.
6. Uncomment the `compatibilityReadTag` method. Leave it unused.
7. Run the app again.
8. Scan the same NFC tag with the NDEF message on it.
9. Observe the crash.








