# Localdev

Localdev is a Ruby command line script to register domains that you sometimes use for local development, and to quickly enable or disable local development for those domains. Only expected to work on OS X. Requires sudo access, as it is manipulating your hosts file.

Available commands:

* `localdev list` — lists the localdev domains
* `localdev add {domain}` — adds the specified domain
* `localdev remove {domain}` — removes the specified domain
* `localdev on` — enables local development
* `localdev off` — disables local development
* `localdev status` — shows the current status

Note: if local development is on, `add` and `remove` commands will immediately update the hosts file and trigger a DNS flush.

Tip: To avoid being prompted by `sudo` for your password, you can add a line like this to your `/etc/sudoers` file (replace `markjaquith` with your user name):

```
markjaquith ALL = NOPASSWD: /usr/bin/localdev
```

Then, just run the a

## Installation

To install Localdev, use RubyGems:

```bash
sudo gem install localdev
```

## Notes

Your list of local development domains is kept in `/etc/hosts-localdev`.

## License & Copyright

Localdev is Copyright Mark Jaquith 2011, and is offered under the terms of the GNU General Public License, version 2, or any later version.