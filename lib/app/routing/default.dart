// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/const.dart';
import 'package:vx/data/database.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vx/xconfig_helper.dart';

const gfw = 'GFW';
const cn = 'CN';
const notCn = '!CN';
const google = 'Google';
// const cnGames = 'CN游戏';
// const private = '私有';
// const gfwWithoutCustomDirect = 'GFW(排除自定义直连)';
// // name of the great domain set and great ip set used in blacklist mode
// const gfwModeProxyDomains = 'GFW模式代理域名';
// const gfwModeProxyIps = 'GFW模式代理IP';
// const cnModeProxyDomains = 'CN模式代理域名';
// const cnModeDirectDomains = 'CN模式直连域名';
// const cnModeDirectIps = 'CN模式直连IP';
// const proxyAllModeProxyDomains = '全局模式代理域名';
// const proxyAllModeDirectDomains = '全局模式直连域名';
// const proxyAllModeDirectIps = '全局模式直连IP';
// const ruBlockModeProxyDomains = 'RU-Block模式代理域名';
// const ruBlockModeProxyIps = 'RU-Block模式代理IP';
// const ruBlockAllModeProxyDomains = 'RU-Block(All)模式代理域名';
// const ruBlockAllModeProxyIps = 'RU-Block(All)模式代理IP';

const ruBlock = 'RU Block';
const ruBlockAll = 'RU Block(All)';

const dnsServerFake = 'Fake DNS Server';
const internalDnsProxy = 'internal-dns-proxy';
const internalDnsDirect = 'internal-dns-direct';
const publicIpTag = 'Public';

enum DefaultRouteMode {
  /// Only banned ip/domain will go through proxy
  @JsonValue('black')
  black(),

  /// Only ip/domain of cn will go through proxy
  @JsonValue('white')
  white(),

  /// All ip/domain will go through proxy
  @JsonValue('proxy_all')
  proxyAll(),
  /* auto */

  @JsonValue('ru_blocked')
  ruBlocked(),

  @JsonValue('ru_blocked_all')
  ruBlockedAll(),

  @JsonValue('realm')
  direct();

  const DefaultRouteMode();

  String toLocalString(AppLocalizations al) {
    switch (this) {
      case DefaultRouteMode.black:
        return 'GFW';
      case DefaultRouteMode.white:
        return 'CN';
      case DefaultRouteMode.proxyAll:
        return al.proxyAll;
      case DefaultRouteMode.ruBlocked:
        return al.ruBlocked;
      case DefaultRouteMode.ruBlockedAll:
        return al.ruBlockedAll;
      case DefaultRouteMode.direct:
        return al.direct;
    }
  }

  String description(BuildContext ctx) {
    switch (this) {
      case DefaultRouteMode.black:
        return AppLocalizations.of(ctx)!.gfwDesc;
      case DefaultRouteMode.white:
        return AppLocalizations.of(ctx)!.cnDesc;
      case DefaultRouteMode.proxyAll:
        return AppLocalizations.of(ctx)!.proxyAllDesc;
      case DefaultRouteMode.ruBlocked:
        return AppLocalizations.of(ctx)!.ruBlockedDesc;
      case DefaultRouteMode.ruBlockedAll:
        return AppLocalizations.of(ctx)!.ruBlockedAllDesc;
      case DefaultRouteMode.direct:
        return 'All traffic will go direct';
    }
  }

  List<DnsServerConfig> getDnsServerConfigs({required AppLocalizations al}) {
    final country = getUserCountryFromLocale();
    return [
      DnsServerConfig(
        name: dnsServerFake,
        fakeDnsServer: FakeDnsServer(poolConfigs: XConfigHelper.fakednsPools),
      ),
      DnsServerConfig(
        name: al.dnsServerProxy,
        plainDnsServer: PlainDnsServer(addresses: ['1.1.1.1:53']),
        cacheDuration: 3600,
        // ipTags: [publicIpTag],
      ),
      DnsServerConfig(
        name: al.dnsServerDirect,
        plainDnsServer: PlainDnsServer(
          addresses: ['1.1.1.1:53', ...(countryDnsServers[country] ?? [])],
          useDefaultDns: true,
        ),
        // ipTags: [publicIpTag],
      ),
    ];
  }

  // this is for displaying to users. and for copying when creating a custom route mode
  List<RuleConfig> displayRouterRules({required AppLocalizations al}) {
    final commonRules = [
      // RuleConfig(
      //   ruleName: al.ruleNameInternalDnsProxyGoProxy,
      //   conditions: [
      //     Condition(inboundTags: [internalDnsProxy]),
      //   ],
      //   selectorTag: defaultProxySelectorTag,
      // ),
      // RuleConfig(
      //   ruleName: al.ruleNameInternalDnsDirectGoDirect,
      //   conditions: [
      //     Condition(inboundTags: [internalDnsDirect]),
      //   ],
      //   outboundTag: directHandlerTag,
      // ),
      RuleConfig(
        ruleName: al.ruleNameProxyDnsServerGoProxy,
        conditions: [
          Condition(inboundTags: [al.dnsServerProxy]),
        ],
        selectorTag: defaultProxySelectorTag,
      ),
      RuleConfig(
        ruleName: al.ruleNameDirectDnsServerGoDirect,
        conditions: [
          Condition(inboundTags: [al.dnsServerDirect]),
        ],
        outboundTag: directHandlerTag,
      ),
      ...(getCommonAppRules(al: al)),
    ];
    switch (this) {
      case DefaultRouteMode.black:
        return [...commonRules, ...(getBlackListSpecificRules(al: al))];
      case DefaultRouteMode.white:
        return [...commonRules, ...(getWhiteListSpecificRules(al: al))];
      case DefaultRouteMode.proxyAll:
        return [...commonRules, ...(getProxyAllSpecificRules(al: al))];
      case DefaultRouteMode.ruBlocked:
        return [...commonRules, ...(getRuBlockSpecificRules(al: al))];
      case DefaultRouteMode.ruBlockedAll:
        return [...commonRules, ...(getRuBlockAllSpecificRules(al: al))];
      case DefaultRouteMode.direct:
        return [...(getDirectSpecificRules(al: al))];
    }
  }

  List<AtomicDomainSet> getAtomicDomainSets({required AppLocalizations al}) {
    final customDirectSet = AtomicDomainSet(
      name: al.customDirect,
      useBloomFilter: false,
    );
    final customProxySet = AtomicDomainSet(
      name: al.customProxy,
      useBloomFilter: false,
    );
    final privateSet = AtomicDomainSet(
      name: al.private,
      useBloomFilter: false,
      geositeConfig: GeositeConfig(codes: ['private']),
    );
    switch (this) {
      case DefaultRouteMode.direct:
        return [];
      case DefaultRouteMode.black:
        return [
          customDirectSet,
          customProxySet,
          AtomicDomainSet(
            name: cn,
            useBloomFilter: true,
            geositeConfig: GeositeConfig(codes: ['cn']),
          ),
          AtomicDomainSet(
            name: gfw,
            useBloomFilter: false,
            geositeConfig: GeositeConfig(codes: ['gfw']),
          ),
          AtomicDomainSet(name: 'Fallback', useBloomFilter: false),
        ];
      case DefaultRouteMode.white:
        return [
          customDirectSet,
          customProxySet,
          privateSet,
          if (Platform.isIOS)
            AtomicDomainSet(
              name: gfw,
              useBloomFilter: false,
              geositeConfig: GeositeConfig(codes: ['gfw']),
            ),
          AtomicDomainSet(
            name: google,
            useBloomFilter: false,
            geositeConfig: GeositeConfig(codes: ['google']),
          ),
          AtomicDomainSet(
            name: cn,
            useBloomFilter: true,
            geositeConfig: GeositeConfig(codes: ['cn', 'apple-cn', 'tld-cn']),
          ),
          AtomicDomainSet(
            name: al.cnGames,
            useBloomFilter: false,
            geositeConfig: GeositeConfig(
              codes: ['category-games'],
              attributes: ['cn'],
            ),
          ),
        ];
      case DefaultRouteMode.proxyAll:
        return [privateSet, customDirectSet, customProxySet];
      case DefaultRouteMode.ruBlocked:
        return [
          customDirectSet,
          customProxySet,
          privateSet,
          AtomicDomainSet(
            name: ruBlock,
            useBloomFilter: true,
            geoUrl: ruGeoSiteSimplifiedUrl,
            geositeConfig: GeositeConfig(codes: ['ru-blocked']),
          ),
        ];
      case DefaultRouteMode.ruBlockedAll:
        return [
          customDirectSet,
          customProxySet,
          privateSet,
          AtomicDomainSet(
            name: ruBlockAll,
            useBloomFilter: true,
            geoUrl: ruGeositeUrl,
            geositeConfig: GeositeConfig(codes: ['ru-blocked-all']),
          ),
        ];
    }
  }

  List<AtomicIpSet> getAtomicIpSets({required AppLocalizations al}) {
    final customDirectSet = AtomicIpSet(name: al.customDirect, inverse: false);
    final customProxySet = AtomicIpSet(name: al.customProxy, inverse: false);
    final privateSet = AtomicIpSet(
      name: al.private,
      inverse: false,
      geoIpConfig: GeoIPConfig(codes: ['private']),
    );
    final publicSet = AtomicIpSet(
      name: 'Public',
      inverse: true,
      geoIpConfig: GeoIPConfig(codes: ['private']),
    );
    switch (this) {
      case DefaultRouteMode.direct:
        return [];
      case DefaultRouteMode.black:
        return [
          AtomicIpSet(
            name: gfw,
            inverse: false,
            geoIpConfig: GeoIPConfig(
              codes: ['telegram', 'google', 'facebook', 'twitter', "tor"],
            ),
          ),
          publicSet,
          AtomicIpSet(
            name: cn,
            inverse: false,
            geoIpConfig: GeoIPConfig(codes: ['cn']),
          ),
        ];
      case DefaultRouteMode.white:
        return [
          customDirectSet,
          customProxySet,
          privateSet,
          AtomicIpSet(
            name: cn,
            inverse: false,
            geoIpConfig: GeoIPConfig(codes: ['cn']),
          ),
          publicSet,
        ];
      case DefaultRouteMode.proxyAll:
        return [privateSet, customDirectSet, customProxySet, publicSet];
      case DefaultRouteMode.ruBlocked || DefaultRouteMode.ruBlockedAll:
        return [
          customDirectSet,
          customProxySet,
          privateSet,
          publicSet,
          AtomicIpSet(
            name: ruBlock,
            inverse: false,
            geoUrl: ruGeoIpUrl,
            geoIpConfig: GeoIPConfig(codes: ['ru-blocked']),
          ),
        ];
    }
  }

  List<GreatDomainSet> getGreatDomainSets({required AppLocalizations al}) {
    switch (this) {
      case DefaultRouteMode.direct:
        return [];
      case DefaultRouteMode.black:
        return [
          GreatDomainSet(
            name: al.gfwModeProxyDomains,
            set: GreatDomainSetConfig(
              name: al.gfwModeProxyDomains,
              inNames: [gfw, al.customProxy, 'Fallback'],
              exNames: [al.customDirect],
            ),
          ),
          GreatDomainSet(
            name: al.cnExcludeGfwDomains,
            oppositeName: '!${al.cnExcludeGfwDomains}',
            set: GreatDomainSetConfig(
              name: al.cnExcludeGfwDomains,
              oppositeName: '!${al.cnExcludeGfwDomains}',
              inNames: [cn, al.cnGames],
              exNames: [if (Platform.isIOS) gfw],
            ),
          ),
        ];
      case DefaultRouteMode.ruBlocked:
        return [
          GreatDomainSet(
            name: al.ruBlockModeProxyDomains,
            set: GreatDomainSetConfig(
              name: al.ruBlockModeProxyDomains,
              inNames: [al.customProxy, ruBlock],
              exNames: [al.customDirect],
            ),
          ),
        ];
      case DefaultRouteMode.ruBlockedAll:
        return [
          GreatDomainSet(
            name: al.ruBlockAllModeProxyDomains,
            set: GreatDomainSetConfig(
              name: al.ruBlockAllModeProxyDomains,
              inNames: [al.customProxy, ruBlockAll],
              exNames: [al.customDirect],
            ),
          ),
        ];
      case DefaultRouteMode.white:
        return [
          GreatDomainSet(
            name: al.cnModeDirectDomains,
            oppositeName: al.cnModeProxyDomains,
            set: GreatDomainSetConfig(
              name: al.cnModeDirectDomains,
              oppositeName: al.cnModeProxyDomains,
              inNames: [al.private, cn, al.cnGames, al.customDirect],
              exNames: [
                al.customProxy,
                if (Platform.isIOS) al.gfwWithoutCustomDirect,
                google,
              ],
            ),
          ),
          if (Platform.isIOS)
            GreatDomainSet(
              name: al.gfwWithoutCustomDirect,
              set: GreatDomainSetConfig(
                name: al.gfwWithoutCustomDirect,
                inNames: [gfw],
                exNames: [al.customDirect],
              ),
            ),
        ];
      case DefaultRouteMode.proxyAll:
        return [
          GreatDomainSet(
            name: al.proxyAllModeDirectDomains,
            oppositeName: al.proxyAllModeProxyDomains,
            set: GreatDomainSetConfig(
              name: al.proxyAllModeDirectDomains,
              oppositeName: al.proxyAllModeProxyDomains,
              inNames: [al.private, al.customDirect],
              exNames: [al.customProxy],
            ),
          ),
        ];
    }
  }

  List<GreatIpSet> getGreatIpSets({required AppLocalizations al}) {
    switch (this) {
      case DefaultRouteMode.direct:
        return [];
      case DefaultRouteMode.black:
        return [
          GreatIpSet(
            name: al.gfwModeProxyIps,
            greatIpSetConfig: GreatIPSetConfig(
              name: al.gfwModeProxyIps,
              inNames: [gfw, al.customProxy],
              exNames: [al.customDirect],
            ),
          ),
        ];
      case DefaultRouteMode.ruBlocked:
        return [
          GreatIpSet(
            name: al.ruBlockModeProxyIps,
            greatIpSetConfig: GreatIPSetConfig(
              name: al.ruBlockModeProxyIps,
              inNames: [al.customProxy, ruBlock],
              exNames: [al.customDirect],
            ),
          ),
        ];
      case DefaultRouteMode.ruBlockedAll:
        return [
          GreatIpSet(
            name: al.ruBlockAllModeProxyIps,
            greatIpSetConfig: GreatIPSetConfig(
              name: al.ruBlockAllModeProxyIps,
              inNames: [al.customProxy, ruBlock],
              exNames: [al.customDirect],
            ),
          ),
        ];
      case DefaultRouteMode.white:
        return [
          GreatIpSet(
            name: al.cnModeDirectIps,
            greatIpSetConfig: GreatIPSetConfig(
              name: al.cnModeDirectIps,
              inNames: [al.private, cn, al.customDirect],
              exNames: [al.customProxy],
            ),
          ),
        ];
      case DefaultRouteMode.proxyAll:
        return [
          GreatIpSet(
            name: al.proxyAllModeDirectIps,
            greatIpSetConfig: GreatIPSetConfig(
              name: al.proxyAllModeDirectIps,
              inNames: [al.private, al.customDirect],
              exNames: [al.customProxy],
            ),
          ),
        ];
    }
  }

  List<RuleConfig> getProxyAllSpecificRules({required AppLocalizations al}) {
    final directIpGoDirectRule = RuleConfig(
      ruleName: al.ruleNameGlobalDirectIp,
      conditions: [
        Condition(dstIpTags: [al.proxyAllModeDirectIps]),
      ],
      outboundTag: directHandlerTag,
    );
    final goProxyRule = RuleConfig(
      ruleName: al.ruleNameDefaultProxy,
      selectorTag: defaultProxySelectorTag,
      matchAll: true,
    );
    final directDomainGoDirectRule = RuleConfig(
      ruleName: al.ruleNameGlobalDirectDomain,
      conditions: [
        Condition(domainTags: [al.proxyAllModeDirectDomains]),
      ],
      outboundTag: directHandlerTag,
    );
    return [
      directIpGoDirectRule,
      directDomainGoDirectRule, //TODO: This can be deleted
      goProxyRule,
    ];
  }

  List<RuleConfig> getWhiteListSpecificRules({required AppLocalizations al}) {
    final directIpGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCnDirectIp,
      conditions: [
        Condition(dstIpTags: [al.cnModeDirectIps]),
      ],
      outboundTag: directHandlerTag,
    );
    final goProxyRule = RuleConfig(
      ruleName: al.ruleNameDefaultProxy,
      selectorTag: defaultProxySelectorTag,
      matchAll: true,
    );
    final directDomainGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCnDirectDomain,
      conditions: [
        Condition(domainTags: [al.cnModeDirectDomains]),
      ],
      outboundTag: directHandlerTag,
    );
    final customProxyDomainGoProxyRule = RuleConfig(
      ruleName: al.ruleNameCustomProxyDomain,
      conditions: [
        Condition(domainTags: [al.customProxy]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final customProxyIpGoProxyRule = RuleConfig(
      ruleName: al.ruleNameCustomProxyIp,
      conditions: [
        Condition(dstIpTags: [al.customProxy]),
      ],
      selectorTag: defaultProxySelectorTag,
    );

    return [
      customProxyDomainGoProxyRule,
      customProxyIpGoProxyRule,
      directIpGoDirectRule,
      directDomainGoDirectRule, //TODO: This can be deleted
      goProxyRule,
    ];
  }

  List<RuleConfig> getDirectSpecificRules({required AppLocalizations al}) {
    return [
      RuleConfig(
        ruleName: al.ruleNameDefaultDirect,
        outboundTag: directHandlerTag,
        matchAll: true,
      ),
    ];
  }

  List<RuleConfig> getBlackListSpecificRules({required AppLocalizations al}) {
    final proxyDomainGoProxyRule = RuleConfig(
      ruleName: al.ruleNameGfwProxyDomain,
      conditions: [
        Condition(domainTags: [al.gfwModeProxyDomains]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final proxyIpGoProxyRule = RuleConfig(
      ruleName: al.ruleNameGfwProxyIp,
      conditions: [
        Condition(dstIpTags: [al.gfwModeProxyIps]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final cnDomainsGoDirectRule = RuleConfig(
      ruleName: al.cnDomainsGoDirectRule,
      conditions: [
        Condition(domainTags: [al.cnExcludeGfwDomains]),
      ],
      outboundTag: directHandlerTag,
    );
    final cnIpsGoDirectRule = RuleConfig(
      ruleName: al.cnIpsGoDirectRule,
      conditions: [
        Condition(dstIpTags: [cn], hasNoDomain: true),
      ],
      outboundTag: directHandlerTag,
    );
    final goDirectRule = RuleConfig(
      ruleName: al.ruleNameDefaultDirect,
      outboundTag: directHandlerTag,
      matchAll: true,
      fallbacks: [
        RuleConfig_Fallback(
          selectorTag: defaultProxySelectorTag,
          action: RuleConfig_Fallback_Action(ipToDomain: true),
          matchAll: true,
        ),
      ],
    );
    final customDirectDomainGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCustomDirectDomain,
      conditions: [
        Condition(domainTags: [al.customDirect]),
      ],
      outboundTag: directHandlerTag,
    );
    final customDirectIpGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCustomDirectIp,
      conditions: [
        Condition(dstIpTags: [al.customDirect]),
      ],
      outboundTag: directHandlerTag,
    );
    return [
      customDirectIpGoDirectRule,
      customDirectDomainGoDirectRule,
      proxyIpGoProxyRule,
      proxyDomainGoProxyRule,
      cnDomainsGoDirectRule,
      cnIpsGoDirectRule,
      goDirectRule,
    ];
  }

  List<RuleConfig> getRuBlockSpecificRules({required AppLocalizations al}) {
    final proxyDomainGoProxyRule = RuleConfig(
      ruleName: al.ruleNameRuBlockProxyDomain,
      conditions: [
        Condition(domainTags: [al.ruBlockModeProxyDomains]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final proxyIpGoProxyRule = RuleConfig(
      ruleName: al.ruleNameRuBlockProxyIp,
      conditions: [
        Condition(dstIpTags: [al.ruBlockModeProxyIps]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final goDirectRule = RuleConfig(
      ruleName: al.ruleNameDefaultDirect,
      outboundTag: directHandlerTag,
      matchAll: true,
    );
    final customDirectDomainGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCustomDirectDomain,
      conditions: [
        Condition(domainTags: [al.customDirect]),
      ],
      outboundTag: directHandlerTag,
    );
    final customDirectIpGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCustomDirectIp,
      conditions: [
        Condition(dstIpTags: [al.customDirect]),
      ],
      outboundTag: directHandlerTag,
    );
    return [
      customDirectIpGoDirectRule,
      customDirectDomainGoDirectRule,
      proxyIpGoProxyRule,
      proxyDomainGoProxyRule,
      goDirectRule,
    ];
  }

  List<RuleConfig> getRuBlockAllSpecificRules({required AppLocalizations al}) {
    final proxyDomainGoProxyRule = RuleConfig(
      ruleName: al.ruleNameRuBlockAllProxyDomain,
      conditions: [
        Condition(domainTags: [al.ruBlockAllModeProxyDomains]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final proxyIpGoProxyRule = RuleConfig(
      ruleName: al.ruleNameRuBlockAllProxyIp,
      conditions: [
        Condition(dstIpTags: [al.ruBlockAllModeProxyIps]),
      ],
      selectorTag: defaultProxySelectorTag,
    );
    final goDirectRule = RuleConfig(
      ruleName: al.ruleNameDefaultDirect,
      outboundTag: directHandlerTag,
      matchAll: true,
    );
    final customDirectDomainGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCustomDirectDomain,
      conditions: [
        Condition(domainTags: [al.customDirect]),
      ],
      outboundTag: directHandlerTag,
    );
    final customDirectIpGoDirectRule = RuleConfig(
      ruleName: al.ruleNameCustomDirectIp,
      conditions: [
        Condition(dstIpTags: [al.customDirect]),
      ],
      outboundTag: directHandlerTag,
    );
    return [
      customDirectIpGoDirectRule,
      customDirectDomainGoDirectRule,
      proxyIpGoProxyRule,
      proxyDomainGoProxyRule,
      goDirectRule,
    ];
  }

  List<RuleConfig> getCommonAppRules({required AppLocalizations al}) {
    final appRules = <RuleConfig>[];
    if (Platform.isAndroid || Platform.isWindows) {
      appRules.add(
        RuleConfig(
          ruleName: al.ruleNameVXTestNodes,
          conditions: [
            Condition(
              allTags: [node],
              appIds: [
                if (Platform.isAndroid)
                  AppId(type: AppId_Type.Exact, value: androidPackageNme),
                if (Platform.isWindows)
                  AppId(type: AppId_Type.Keyword, value: 'vx.exe'),
              ],
            ),
          ],
          outboundTag: directHandlerTag,
        ),
      );
    }
    appRules.add(
      RuleConfig(
        ruleName: al.ruleNameProxyApp,
        conditions: [
          Condition(appTags: [al.proxy]),
        ],
        selectorTag: defaultProxySelectorTag,
      ),
    );
    appRules.add(
      RuleConfig(
        ruleName: al.ruleNameDirectApp,
        conditions: [
          Condition(appTags: [al.direct]),
        ],
        outboundTag: directHandlerTag,
      ),
    );
    return appRules;
  }

  List<String> internalDnsServers({required AppLocalizations al}) {
    switch (this) {
      case DefaultRouteMode.direct:
        return [al.dnsServerDirect];
      default:
        return [al.dnsServerDirect, al.dnsServerProxy];
    }
  }

  List<DnsRuleConfig> dnsRules({required AppLocalizations al}) {
    switch (this) {
      case DefaultRouteMode.direct:
        return [
          DnsRuleConfig(ruleName: al.all, dnsServerName: al.dnsServerDirect),
        ];
      case DefaultRouteMode.black:
        return [
          DnsRuleConfig(
            dnsServerName: dnsServerFake,
            ruleName: al.dnsRuleNameGfwProxyFake,
            includedTypes: [DnsType.DnsType_A, DnsType.DnsType_AAAA],
            domainTags: [al.gfwModeProxyDomains, '!${al.cnExcludeGfwDomains}'],
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameGfwProxy,
            domainTags: [al.gfwModeProxyDomains],
            dnsServerName: al.dnsServerProxy,
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameDefaultDirect,
            dnsServerName: al.dnsServerDirect,
          ),
        ];
      case DefaultRouteMode.ruBlocked:
        return [
          DnsRuleConfig(
            dnsServerName: dnsServerFake,
            ruleName: al.dnsRuleNameRuBlockProxyFake,
            includedTypes: [DnsType.DnsType_A, DnsType.DnsType_AAAA],
            domainTags: [al.ruBlockModeProxyDomains],
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameRuBlockProxy,
            domainTags: [al.ruBlockModeProxyDomains],
            dnsServerName: al.dnsServerProxy,
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameDefaultDirect,
            dnsServerName: al.dnsServerDirect,
          ),
        ];
      case DefaultRouteMode.ruBlockedAll:
        return [
          DnsRuleConfig(
            dnsServerName: dnsServerFake,
            ruleName: al.dnsRuleNameRuBlockAllProxyFake,
            includedTypes: [DnsType.DnsType_A, DnsType.DnsType_AAAA],
            domainTags: [al.ruBlockAllModeProxyDomains],
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameRuBlockAllProxy,
            domainTags: [al.ruBlockAllModeProxyDomains],
            dnsServerName: al.dnsServerProxy,
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameDefaultDirect,
            dnsServerName: al.dnsServerDirect,
          ),
        ];
      case DefaultRouteMode.white:
        return [
          DnsRuleConfig(
            dnsServerName: dnsServerFake,
            ruleName: al.dnsRuleNameCnProxyFake,
            includedTypes: [DnsType.DnsType_A, DnsType.DnsType_AAAA],
            domainTags: [al.cnModeProxyDomains],
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameCnProxy,
            domainTags: [al.cnModeProxyDomains],
            dnsServerName: al.dnsServerProxy,
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameDefaultDirect,
            dnsServerName: al.dnsServerDirect,
          ),
        ];
      case DefaultRouteMode.proxyAll:
        return [
          DnsRuleConfig(
            dnsServerName: dnsServerFake,
            ruleName: al.dnsRuleNameProxyAllProxyFake,
            includedTypes: [DnsType.DnsType_A, DnsType.DnsType_AAAA],
            domainTags: [al.proxyAllModeProxyDomains],
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameProxyAllProxy,
            domainTags: [al.proxyAllModeProxyDomains],
            dnsServerName: al.dnsServerProxy,
          ),
          DnsRuleConfig(
            ruleName: al.dnsRuleNameDefaultDirect,
            dnsServerName: al.dnsServerDirect,
          ),
        ];
    }
  }
}

bool isDefaultRouteMode(String routeMode, BuildContext ctx) {
  for (var mode in DefaultRouteMode.values) {
    if (mode.toLocalString(AppLocalizations.of(ctx)!) == routeMode) {
      return true;
    }
  }
  return false;
}

String getCustomDirect(BuildContext ctx) {
  return AppLocalizations.of(ctx)!.customDirect;
}

String getCustomProxy(BuildContext ctx) {
  return AppLocalizations.of(ctx)!.customProxy;
}

String getProxySetName(BuildContext ctx) {
  return AppLocalizations.of(ctx)!.proxy;
}

String getDirectSetName(BuildContext ctx) {
  return AppLocalizations.of(ctx)!.direct;
}

const countryDnsServers = {
  'CN': ['223.5.5.5:53'],
  'RU': ['77.88.8.8:53'],
};
