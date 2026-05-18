# bentopdf-self-hosted

Self-hosted BentoPDF (Simple Mode), deployed via Netlify at https://pdf-carl.netlify.app/.

Source: https://github.com/alam00000/bentopdf

## Updating

Run ./update.sh to fetch the latest release, or ./update.sh v2.8.5 to pin a specific version.

The script downloads the dist-simple-X.X.X.zip from GitHub releases, replaces local files, commits, and pushes. Netlify auto-deploys.