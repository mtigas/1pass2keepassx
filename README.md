```shell
git clone https://github.com/mtigas/1pass2keepassx.git
cd 1pass2keepassx
bundle install
```

## Using: Current versions of 1Password

*(As of August 10, 2014.)*

Note that newer versions of 1Password actually use a folder
as the `.1pif` "file" and the actual legacy PIF-format file
is inside it. So you'd want to do something like this:

```shell
bundle exec ruby 1pass2keepass.rb ${YOURFILE}/data.1pif
```

That'll spit out the KeePassX XML to your console. What you
probably want is to save this to an XML. So redirect the output.

Putting it all together, you'd do something like this:

```shell
bundle exec ruby 1pass2keepass.rb ~/Desktop/pass.1pif/data.1pif > ~/Desktop/keepass.xml
```


## Using: Older versions of 1Password

Basically like above, but directly accessing the `.1pif` file.

```shell
bundle exec ruby 1pass2keepass.rb $YOURFILE

#i.e.:
bundle exec ruby 1pass2keepass.rb ~/Desktop/pass.1pif > ~/Desktop/keepass.xml
```
