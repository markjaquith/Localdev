# Localdev

Localdev is a Ruby command line script to register domains that you sometimes use for local development, and to quickly enable or disable local development for those domains. Only expected to work on OS X. Requires sudo access, as it is manipulating your hosts file.

Available commands:

* `add {domain}` — adds the specified domain
* `remove {domain}` — removes the specified domain
* `on` — enables local development
* `off` — disables local development
* `status` — shows the current status

Note: if local development is on, `add` and `remove` commands will immediately update the hosts file and trigger a DNS flush.

Examples:

```bash
localdev add example.com
localdev add another.example.com
localdev add old.example.com
localdev remove old.example.com
localdev on
localdev off
localdev status
````

Set it up with an alias so you can use it with `localdev`, as shown above:

```bash
alias localdev="ruby /path/to/your/localdev.rb"
```

Your list of local development domains is kept in `/etc/hosts-localdev`.