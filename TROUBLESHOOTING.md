## Known Issues

Blazar does not properly setup it’s database via puppet run. Manually do this after running puppet:

```
blazar-db-manage --config-file /etc/blazar/blazar.conf upgrade head
```
