# Metadata
libPhoneNumber is using metadata from Google's libphonenumber.

The metadata exists in PhoneNumberMetadata.json and the original XML can be found at [Original/PhoneNumberMetadata.xml](https://github.com/sereivoanyong/libPhoneNumber/blob/master/libPhoneNumber/Resources/Original/PhoneNumberMetadata.xml)

## Updating the metadata

We try to keep the metadata of libPhoneNumber up to date and making sure you are running on the latest release will be sufficient for most apps

However, you can also update the metadata youself by following these steps:
1. Download a newer version of the XML metadata file from [libPhoneNumber](https://github.com/googlei18n/libphonenumber/blob/master/resources/)
2. Replace the XML file in your libPhoneNumber projects. 
3. Run  
```bash
./update.sh
```

You will need a python library called 'xmljson' installed. You can install it with pip
```bash
pip install xmljson
```
