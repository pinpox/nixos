{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.sso;

  users = [ cfg.ldapAutheliaUser ] ++ cfg.ldapUsers;

  toLdif = (u: ''
    dn: cn=${u.username},ou=users,dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}
    objectClass: organizationalPerson
    objectClass: inetOrgPerson
    sn: ${u.username}
    cn: ${u.username}
    displayName: ${u.displayName or u.username}
    mail: ${u.email}
    userPassword: ${u.password}
  '');

  getMembers = group: users: (lib.concatStringsSep "\n" (
    map (u: "member: cn=${u.username},ou=users,dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}")
      (builtins.filter (f: builtins.elem group f.groups) users)
  ));

  ldifGroups = users: (map
    (g: ''
      dn: cn=${g},ou=groups,dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}
      cn: ${g}
      objectClass: top
      objectClass: groupOfNames
      description: tagGroup
      ${getMembers g users}

    '')
    (lib.lists.unique (builtins.concatMap (u: u.groups) users)));
in
{

  config = mkIf config.pinpox.services.sso.enable {

    services.openldap = {
      enable = true;

      settings.children = {
        "olcDatabase={1}mdb".attrs = {
          objectClass = [ "olcDatabaseConfig" "olcMdbConfig" ];
          olcDatabase = "{1}mdb";
          olcDbDirectory = "/var/lib/openldap/db";
          olcSuffix = "dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}";
          olcAccess = "to *  by * read";
          olcRootDN = "cn=${cfg.ldapRootCN},dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}";
          olcRootPW = cfg.ldapRootPW;
        };

        "cn=module{0}".attrs = {
          objectClass = "olcModuleList";
          olcModuleLoad = "argon2";
        };

        "cn=schema".includes =
          map (schema: "${pkgs.openldap}/etc/schema/${schema}.ldif")
            [ "core" "cosine" "inetorgperson" "nis" ];
      };

      # Contents are immutable at runtime, and adding user accounts etc.
      # is done statically in the LDIF-formatted contents in this folder.
      declarativeContents."dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}" = ''
        dn: dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}
        dc: ${cfg.ldapDomainName}
        o: ${cfg.ldapDomainName}.${cfg.ldapDomainTld} LDAP server
        description: Root entry for ${cfg.ldapDomainName}.${cfg.ldapDomainTld}
        objectClass: top
        objectClass: dcObject
        objectClass: organization

        dn: ou=users,dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}
        ou: users
        description: All users
        objectClass: top
        objectClass: organizationalUnit

        dn: ou=groups,dc=${cfg.ldapDomainName},dc=${cfg.ldapDomainTld}
        ou: groups
        description: All groups
        objectClass: top
        objectClass: organizationalUnit

        # Users
        ${lib.concatStringsSep "\n" (map toLdif users)}

        # Groups
        ${lib.concatStringsSep "\n" (ldifGroups users)}
      '';
    };
  };
}
