# hcp-packer-cli-rb

[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)

## Development

```shell
$EDITOR .envrc-private # add client id, client secret
direnv allow
bundle install
bundle exec exe/hcp-packer auth
bundle exec exe/hcp-packer list-buckets
```
