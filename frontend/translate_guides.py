import json

data = {
  'guide_title': ('Protection Guides', 'Miongozo ya Ulinzi'),
  'guide_step': ('STEP', 'HATUA'),
  'guide_next': ('NEXT STEP', 'HATUA INAYOFUATA'),
  'guide_finish': ('FINISH', 'KAMILISHA'),
  'guide_back': ('BACK', 'RUDI'),
  'guide_sim_swap': ('SIM Swap Protection', 'Ulinzi wa SIM Swap'),
  'guide_sim_desc': ('Learn how to protect yourself from SIM swap fraud', 'Jifunze jinsi ya kujilinda dhidi ya ulaghai wa SIM swap'),
  'guide_social': ('Social Media Safety', 'Usalama wa Mitandao ya Kijamii'),
  'guide_social_desc': ('Secure your social media accounts against hackers', 'Linda akaunti zako za mitandao ya kijamii dhidi ya wadukuzi'),
  'guide_banking': ('Banking Security', 'Usalama wa Kibenki'),
  'guide_banking_desc': ('Best practices for mobile & online banking', 'Mbinu bora za benki kupitia simu na mtandao'),
  'guide_identity': ('Identity Theft Guard', 'Ulinzi wa Wizi wa Utambulisho'),
  'guide_identity_desc': ('Steps to prevent and respond to identity theft', 'Hatua za kuzuia na kukabiliana na wizi wa utambulisho'),
  'guide_password': ('Password Health', 'Afya ya Nywila'),
  'guide_password_desc': ('Check and improve your password strength', 'Kagua na boresha nguvu ya nywila yako'),
  'guide_wifi': ('Wi-Fi Security', 'Usalama wa Wi-Fi'),
  'guide_wifi_desc': ('Stay safe on public and home networks', 'Baki salama kwenye mitandao ya umma na nyumbani'),

  # SIM Swap
  'guide_sim_1_title': ('Recognize the Signs', 'Tambua Dalili'),
  'guide_sim_1_desc': ('If your phone suddenly loses network signal for an extended period, you may be a SIM swap victim. Act immediately — every second counts.', 'Ikiwa simu yako inapoteza mtandao ghafla kwa muda mrefu, unaweza kuwa mwathiriwa wa SIM swap. Chukua hatua mara moja.'),
  'guide_sim_2_title': ('Contact Your Carrier', 'Wasiliana na Mtoa Huduma Wako'),
  'guide_sim_2_desc': ('Call Safaricom (100), Airtel (100), or your carrier from another phone to report the suspicious SIM swap and request an immediate block.', 'Piga simu Safaricom (100), Airtel (100), au mtoa huduma wako kutoka simu nyingine ili kuripoti na kuomba kufungiwa mara moja.'),
  'guide_sim_2_action': ('CALL SAFARICOM', 'PIGA SIMU SAFARICOM'),
  'guide_sim_3_title': ('Lock Your Accounts', 'Funga Akaunti Zako'),
  'guide_sim_3_desc': ('Call your bank immediately to freeze online and mobile banking. Your SIM is the key to M-Pesa and SMS-based authentication.', 'Piga simu benki yako mara moja ili kufunga huduma za kibenki mtandaoni. SIM yako ni ufunguo wa M-Pesa na uthibitishaji wa SMS.'),
  'guide_sim_4_title': ('Report to Police', 'Ripoti kwa Polisi'),
  'guide_sim_4_desc': ('File a report at the nearest police station or through the eCitizen portal. You\'ll need the OB number for insurance or bank claims.', 'Toa ripoti katika kituo cha polisi kilicho karibu au kupitia mtandao wa eCitizen. Utahitaji nambari ya OB kwa madai ya bima au benki.'),
  'guide_sim_5_title': ('Monitor Your Accounts', 'Kagua Akaunti Zako'),
  'guide_sim_5_desc': ('For the next 30 days, watch all your bank statements and M-Pesa history for unauthorized transactions. Report anything suspicious immediately.', 'Kwa siku 30 zijazo, kagua taarifa zako zote za benki na historia ya M-Pesa kwa miamala isiyoidhinishwa. Ripoti chochote kinachotia shaka mara moja.'),

  # Social Media
  'guide_soc_1_title': ('Enable Two-Factor Authentication', 'Washa Uthibitishaji wa Hatua Mbili'),
  'guide_soc_1_desc': ('Add 2FA to all your social media accounts. Use an authenticator app like Google Authenticator instead of SMS for stronger security.', 'Ongeza 2FA kwenye akaunti zako zote za mitandao ya kijamii. Tumia programu ya uthibitishaji kama Google Authenticator badala ya SMS kwa usalama zaidi.'),
  'guide_soc_2_title': ('Review Privacy Settings', 'Kagua Mipangilio ya Faragha'),
  'guide_soc_2_desc': ('Limit who can see your posts, friends list, and personal information. Set your profile to private and restrict friend requests to friends-of-friends.', 'Punguza wanaoweza kuona machapisho yako, orodha ya marafiki, na maelezo ya kibinafsi. Weka wasifu wako kuwa wa faragha.'),
  'guide_soc_3_title': ('Beware of Phishing Links', 'Jihadhari na Viungo vya Hadaa'),
  'guide_soc_3_desc': ('Don\'t click suspicious links in DMs or comments, even from friends. Hackers often hijack accounts and send malicious links to contacts.', 'Usibonyeze viungo vinavyotia shaka kwenye jumbe (DMs) au maoni, hata kutoka kwa marafiki. Wadukuzi hutumia akaunti zilizodukuliwa kutuma viungo hatari.'),
  'guide_soc_4_title': ('Use Strong Passwords', 'Tumia Nywila Imara'),
  'guide_soc_4_desc': ('Use a unique, complex password for each social media account. Never reuse your email or banking password for social media.', 'Tumia nywila ya kipekee na ngumu kwa kila akaunti ya mtandao wa kijamii. Usitumie nywila ya barua pepe au benki yako kwa mitandao ya kijamii.'),
  'guide_soc_5_title': ('Audit Connected Apps', 'Kagua Programu Zilizounganishwa'),
  'guide_soc_5_desc': ('Remove third-party apps and website logins you no longer use. These forgotten connections can become backdoors for attackers.', 'Ondoa programu za watu wengine na tovuti ambazo hutumii tena. Miunganisho hii iliyosahaulika inaweza kuwa milango ya wadukuzi.'),

  # Banking Security
  'guide_bnk_1_title': ('Never Share PINs or OTPs', 'Usishiriki PIN au OTP Kamwe'),
  'guide_bnk_1_desc': ('Your M-Pesa PIN, ATM PIN, and one-time passwords should never be shared with anyone — not even someone claiming to be from your bank or Safaricom.', 'PIN yako ya M-Pesa, ATM, na nywila za mara moja (OTPs) hazipaswi kushirikiwa na mtu yeyote - hata mtu anayedai kuwa anatoka benki yako au Safaricom.'),
  'guide_bnk_2_title': ('Verify Before Transacting', 'Thibitisha Kabla ya Kufanya Muamala'),
  'guide_bnk_2_desc': ('Always confirm the recipient\'s name before completing M-Pesa or bank transfers. A wrong transaction is very difficult to reverse.', 'Daima thibitisha jina la mpokeaji kabla ya kukamilisha muamala wa M-Pesa au benki. Muamala mbaya ni vigumu sana kuurejesha.'),
  'guide_bnk_3_title': ('Use Official Apps Only', 'Tumia Programu Rasmi Tu'),
  'guide_bnk_3_desc': ('Download banking apps only from Google Play Store or Apple App Store. Fake banking apps are a common tool for stealing credentials.', 'Pakua programu za benki pekee kutoka Google Play Store au Apple App Store. Programu bandia za benki ni zana ya kawaida ya kuiba utambulisho.'),
  'guide_bnk_4_title': ('Enable Transaction Alerts', 'Washa Arifa za Miamala'),
  'guide_bnk_4_desc': ('Set up SMS and email notifications for all account activity. Instant alerts help you catch unauthorized transactions immediately.', 'Weka arifa za SMS na barua pepe kwa shughuli zote za akaunti. Arifa za hapo hapo zinakusaidia kukamata miamala isiyoidhinishwa mara moja.'),
  'guide_bnk_5_title': ('Report Fraud Immediately', 'Ripoti Ulaghai Mara Moja'),
  'guide_bnk_5_desc': ('If you notice unauthorized activity, call your bank\'s fraud line and Safaricom\'s M-Pesa support (234) without delay.', 'Ukiona shughuli isiyoidhinishwa, piga simu nambari ya udanganyifu ya benki yako na usaidizi wa M-Pesa wa Safaricom (234) bila kuchelewa.'),
  'guide_bnk_5_action': ('CALL M-PESA SUPPORT', 'PIGA SIMU USAIDIZI WA M-PESA'),

  # Identity Theft Guard
  'guide_id_1_title': ('Guard Your ID Documents', 'Linda Hati Zako za Vitambulisho'),
  'guide_id_1_desc': ('Never share photos of your National ID, passport, or KRA PIN on social media or with unverified websites. Criminals use these to open accounts in your name.', 'Kamwe usishiriki picha za Kitambulisho chako cha Taifa, pasipoti, au KRA PIN kwenye mitandao ya kijamii au tovuti zisizothibitishwa. Wahalifu huzitumia kufungua akaunti kwa jina lako.'),
  'guide_id_2_title': ('Shred Sensitive Documents', 'Chana Hati Nyeti'),
  'guide_id_2_desc': ('Destroy old bank statements, utility bills, and any documents containing personal information. Dumpster diving is a real threat.', 'Haribu taarifa za zamani za benki, bili za huduma, na hati zozote zenye habari za kibinafsi. Kuchakura kwenye majalala ni tishio halisi.'),
  'guide_id_3_title': ('Monitor Your Credit', 'Fuatilia Rekodi Yako ya Mikopo'),
  'guide_id_3_desc': ('Check your CRB (Credit Reference Bureau) report regularly for unauthorized loans or accounts opened in your name. You can check via Metropol or TransUnion.', 'Angalia ripoti yako ya CRB (Credit Reference Bureau) mara kwa mara kwa mikopo isiyoidhinishwa au akaunti zilizofunguliwa kwa jina lako. Unaweza kuangalia kupitia Metropol au TransUnion.'),
  'guide_id_4_title': ('Be Cautious Online', 'Kuwa Mwangalifu Mtandaoni'),
  'guide_id_4_desc': ('Avoid entering personal details on unfamiliar or unsecured websites. Look for the padlock icon (HTTPS) before submitting any information.', 'Epuka kuingiza maelezo ya kibinafsi kwenye tovuti zisizojulikana au zisizo salama. Tafuta ikoni ya kufuli (HTTPS) kabla ya kuwasilisha taarifa yoyote.'),
  'guide_id_5_title': ('Act Fast If Compromised', 'Chukua Hatua Haraka Ikiwa Umedukuliwa'),
  'guide_id_5_desc': ('Report identity theft to the DCI Cybercrime Unit immediately. File an official complaint and notify your bank and mobile provider.', 'Ripoti wizi wa utambulisho kwa Kitengo cha Uhalifu wa Mtandao cha DCI mara moja. Toa malalamiko rasmi na ujulishe benki yako na mtoa huduma wako wa simu.'),
  'guide_id_5_action': ('CALL DCI CYBERCRIME', 'PIGA SIMU DCI MTANDAO'),

  # Password Health
  'guide_pwd_1_title': ('Use Long, Unique Passwords', 'Tumia Nywila Ndefu na za Kipekee'),
  'guide_pwd_1_desc': ('Each account should have a password of at least 12 characters mixing uppercase, lowercase, numbers, and symbols. Length beats complexity.', 'Kila akaunti inapaswa kuwa na nywila ya angalau herufi 12 inayochanganya herufi kubwa, ndogo, nambari, na alama. Urefu unashinda ugumu.'),
  'guide_pwd_2_title': ('Use a Password Manager', 'Tumia Kidhibiti Nywila'),
  'guide_pwd_2_desc': ('Apps like Bitwarden or Google Password Manager store all your passwords securely so you only need to remember one master password.', 'Programu kama Bitwarden au Google Password Manager huhifadhi nywila zako zote kwa usalama ili uhitaji kukumbuka nywila kuu moja tu.'),
  'guide_pwd_3_title': ('Never Reuse Passwords', 'Kamwe Usitumie Nywila Zilizotumika'),
  'guide_pwd_3_desc': ('If one service is breached, reused passwords expose all your other accounts. Each account must have its own unique password.', 'Ikiwa huduma moja itadukuliwa, nywila zinazotumiwa tena zinaweka akaunti zako zote hatarini. Kila akaunti lazima iwe na nywila yake ya kipekee.'),
  'guide_pwd_4_title': ('Change Compromised Passwords', 'Badilisha Nywila Zilizodukuliwa'),
  'guide_pwd_4_desc': ('If a service reports a data breach, change your password there immediately. Check haveibeenpwned.com to see if your email has been exposed.', 'Ikiwa huduma itaripoti ukiukaji wa data, badilisha nywila yako hapo mara moja. Angalia haveibeenpwned.com ili uone ikiwa barua pepe yako imefichuliwa.'),
  'guide_pwd_5_title': ('Try Passphrases', 'Jaribu Vifungu vya Nywila'),
  'guide_pwd_5_desc': ('Combine random words like "Sunset-Mango-River-42" for passwords that are both strong and easy to remember. Avoid common phrases or song lyrics.', 'Changanya maneno kwa mpangilio bila mpangilio kama "Machweo-Embe-Mto-42" kwa nywila ambazo ni thabiti na rahisi kukumbuka. Epuka vifungu vya kawaida au mashairi ya nyimbo.'),

  # Wi-Fi Security
  'guide_wifi_1_title': ('Avoid Public Wi-Fi for Banking', 'Epuka Wi-Fi za Umma kwa Huduma za Kibenki'),
  'guide_wifi_1_desc': ('Never access banking, M-Pesa, or other sensitive accounts on public Wi-Fi at restaurants, malls, or airports. Use mobile data instead.', 'Kamwe usifikie benki, M-Pesa, au akaunti nyingine nyeti kwenye Wi-Fi za umma katika mikahawa, maduka makubwa, au viwanja vya ndege. Tumia data ya simu badala yake.'),
  'guide_wifi_2_title': ('Use a VPN', 'Tumia VPN'),
  'guide_wifi_2_desc': ('A Virtual Private Network encrypts all your data on public networks, making it invisible to hackers on the same Wi-Fi.', 'Mtandao wa Kibinafsi (VPN) husimba data yako yote kwenye mitandao ya umma, na kuifanya ionekane kwa wadukuzi kwenye Wi-Fi hiyo.'),
  'guide_wifi_3_title': ('Secure Your Home Wi-Fi', 'Linda Wi-Fi Yako ya Nyumbani'),
  'guide_wifi_3_desc': ('Change the default router password and Wi-Fi name. Use WPA3 or WPA2 encryption — never leave your network open or use WEP.', 'Badilisha nywila chaguomsingi ya ruta na jina la Wi-Fi. Tumia usimbaji fiche wa WPA3 au WPA2 - usiwahi kuacha mtandao wako wazi au kutumia WEP.'),
  'guide_wifi_4_title': ('Forget Old Networks', 'Sahau Mitandao ya Zamani'),
  'guide_wifi_4_desc': ('Remove saved Wi-Fi networks you no longer use from your device. Your phone could auto-connect to a malicious network with the same name.', 'Ondoa mitandao ya Wi-Fi iliyohifadhiwa ambayo hutumii tena kutoka kwenye kifaa chako. Simu yako inaweza kuunganishwa kiotomatiki kwenye mtandao mbaya wenye jina sawa.'),
  'guide_wifi_5_title': ('Watch for Fake Hotspots', 'Jihadhari na Mitandao Bandia'),
  'guide_wifi_5_desc': ('Hackers create fake Wi-Fi networks that mimic coffee shops, hotels, or airports. Always confirm the exact network name with staff before connecting.', 'Wadukuzi hutengeneza mitandao bandia ya Wi-Fi inayoiga mikahawa, hoteli, au viwanja vya ndege. Daima thibitisha jina kamili la mtandao na wafanyakazi kabla ya kuunganishwa.'),
}

out = ""
for k, v in data.items():
    en = str(v[0]).replace("'", "\\'")
    sw = str(v[1]).replace("'", "\\'")
    out += f"  '{k}': {{\n    'en': '{en}',\n    'sw': '{sw}',\n  }},\n"

print(out)
