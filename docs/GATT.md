# GATT Services & Characterstics

The Generic Attribute Profile (GATT) establishes in detail how to exchange all profile and user data over a BLE connection.

GATT also provides the reference framework for all GATT-based profiles (discussed in “SIG-defined GATT-based profiles”), which cover precise use cases and ensure interoperability between devices from different vendors. All standard BLE profiles are therefore based on GATT and must comply with it to operate correctly. This makes GATT a key section of the BLE specification, because every single item of data relevant to applications and users must be formatted, packed, and sent according to its rules.

GATT uses the Attribute Protocol (detailed in “Attribute Protocol (ATT)”) as its transport protocol to exchange data between devices. This data is organized hierarchically in sections called services, which group conceptually related pieces of user data called characteristics. This determines many fundamental aspects of GATT. 

## Roles

As with any other protocol or profile in the Bluetooth specification, GATT starts by defining the roles that interacting devices can adopt:

### Client

The GATT client corresponds to the ATT client discussed in “Attribute Protocol (ATT)”. It sends requests to a server and receives responses (and server-initiated updates) from it. The GATT client does not know anything in advance about the server’s attributes, so it must first inquire about the presence and nature of those attributes by performing service discovery. After completing service discovery, it can then start reading and writing attributes found in the server, as well as receiving server-initiated updates.

### Server

The GATT server corresponds to the ATT server discussed in “Attribute Protocol (ATT)”. It receives requests from a client and sends responses back. It also sends server-initiated updates when configured to do so, and it is the role responsible for storing and making the user data available to the client, organized in attributes. *Every BLE device sold must include at least a basic GATT server that can respond to client requests, even if only to return an error response*.

### UUIDs

A universally unique identifier (UUID) is a 128-bit (16 bytes) number that is guaranteed (or has a high probability) to be globally unique. UUIDs are used in many protocols and applications other than Bluetooth, and their format, usage, and generation is specified in ITU-T Rec. X.667, alternatively known as ISO/IEC 9834-8:2005.

For efficiency, and because 16 bytes would take a large chunk of the 27-byte data payload length of the Link Layer, the BLE specification adds two additional UUID formats: 16-bit and 32-bit UUIDs. These shortened formats can be used only with UUIDs that are defined in the Bluetooth specification (i.e., that are listed by the Bluetooth SIG as standard Bluetooth UUIDs).

To reconstruct the full 128-bit UUID from the shortened version, insert the 16- or 32-bit short value (indicated by xxxxxxxx, including leading zeros) into the Bluetooth Base UUID:

```bash
xxxxxxxx-0000-1000-8000-00805F9B34FB
```

The SIG provides (shortened) UUIDs for all the types, services, and profiles that it defines and specifies. But if your application needs its own, either because the ones offered by the SIG do not cover your requirements or because you want to implement a new use case not previously considered in the profile specifications, you can generate them using the ITU’s UUID generation page.

Shortening is not available for UUIDs that are not derived from the Bluetooth Base UUID (commonly called vendor-specific UUIDs). In these cases, you’ll need to use the full 128-bit UUID value at all times.

### Attributes

Attributes are the smallest data entity defined by GATT (and ATT). They are addressable pieces of information that can contain relevant user data (or metadata) about the structure and grouping of the different attributes contained within the server. Both GATT and ATT can work only with attributes, so for clients and servers to interact, all information must be organized in this form.

Conceptually, attributes are always located on the server and accessed (and potentially modified) by the client. The specification defines attributes only conceptually, and it does not force the ATT and GATT implementations to use a particular internal storage format or mechanism. Because attributes contain both static definitions of invariable nature and also actual user (often sensor) data that is bound to change rapidly with time (as discussed in “Attribute and Data Hierarchy”), attributes are usually stored in a mixture of nonvolatile memory and RAM.

Each and every attribute contains information about the attribute itself and then the actual data, in the fields described in the following sections.

### Handle

The attribute handle is a unique 16-bit identifier for each attribute on a particular GATT server. It is the part of each attribute that makes it addressable, and it is guaranteed not to change (with the caveats described in “Attribute Caching”) between transactions or, for bonded devices, even across connections. Because value 0x0000 denotes an invalid handle, the amount of handles available to every GATT server is 0xFFFF (65535), although in practice, the number of attributes in a server is typically closer to a few dozen.

```bash
NOTE
Whenever used in the context of attribute handles, the term handle range refers to all attributes with handles contained between two given boundaries. For example, handle range 0x0100-0x010A would refer to any attribute with a handle between 0x0100 and 0x010A.
```

Within a GATT server, the growing values of handles determine the ordered sequence of attributes that a client can access. But gaps between handles are allowed, so a client cannot rely on a contiguous sequence to guess the location of the next attribute. Instead, the client must use the discovery feature (“Service and Characteristic Discovery”) to obtain the handles of the attributes it is interested in.

### Type

The attribute type is nothing other than a UUID. This can be a 16-, 32-, or 128-bit UUID, taking up 2, 4, or 16 bytes, respectively. The type determines the kind of data present in the value of the attribute, and mechanisms are available to discover attributes based exclusively on their type.

Although the attribute type is always a UUID, many kinds of UUIDs can be used to fill in the type. They can be standard UUIDs that determine the layout of the GATT server’s attribute hierarchy, such as the service or characteristic UUIDs, profile UUIDs that specify the kind of data contained in the attribute, such as *Heart Rate Measurement* or *Temperature*, and even proprietary, vendor-specific UUIDs, the meaning of which is assigned by the vendor and depends on the implementation.

### Permissions

Permissions are metadata that specify which ATT operations (see “ATT operations”) can be executed on each particular attribute and with which specific security requirements.

ATT and GATT define the following permissions:

#### Access Permissions

Similar to file permissions, access permissions determine whether the client can read or write (or both) an attribute value (introduced in “Value”). Each attribute can have one of the following access permissions:

* None  
The attribute can neither be read nor written by a client.

* Readable  
The attribute can be read by a client.

* Writable  
The attribute can be written by a client.

* Readable and writable  
The attribute can be both read and written by the client.

#### Encryption

Determines whether a certain level of encryption is required for this attribute to be accessed by the client. (See “Authentication”, “Security Modes and Procedures”, and “Security Modes” for more information on authentication and encryption.) These are the allowed encryption permissions, as defined by GATT:

* No encryption required (Security Mode 1, Level 1)  
The attribute is accessible on a plain-text, non-encrypted connection.

* Unauthenticated encryption required (Security Mode 1, Level 2)  
The connection must be encrypted to access this attribute, but the encryption keys do not need to be authenticated (although they can be).

* Authenticated encryption required (Security Mode 1, Level 3)  
The connection must be encrypted with an authenticated key to access this attribute.

#### Authorization

Determines whether user permission (also known as authorization, as discussed in “Security Modes and Procedures”) is required to access this attribute. An attribute can choose only between requiring or not requiring authorization:

* No authorization required  
Access to this attribute does not require authorization.

* Authorization required  
Access to this attribute requires authorization.

All permissions are independent from each other and can be freely combined by the server, which stores them in a per-attribute basis.

### Value

The attribute value holds the actual data content of the attribute. There are no restrictions on the type of data it can contain (you can imagine it as a non-typed buffer that can be cast to whatever the actual type is, based on the attribute type), although its maximum length is limited to 512 bytes by the specification.

Depending on the attribute type, the value can hold additional information about attributes themselves or actual, useful, user-defined application data. This is the part of an attribute that a client can freely access (with the proper permissions permitting) to both read and write. All other entities make up the structure of the attribute and cannot be modified or accessed directly by the client (although the client uses the handle and UUID indirectly in most of the exchanges with the server).


