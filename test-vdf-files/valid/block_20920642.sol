// ETH BLOCK 20920642 -> prevRandao: 2656751508725187512486344122081204096368588122458517885621621007542366135775
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../../src/libraries/BigNumbers.sol";

library ValidVDF_20920642 {
    function getX() external pure returns (BigNumber memory) {
        return BigNumber({
            val: hex"05dfab065ebfe4057e3a4cb25d397852db2a25b6174131642cf45e612f4665df",
            bitlen: 251
        });
    }

    function getY() external pure returns (BigNumber memory) {
        return BigNumber({
            val: hex"4a236b51f21188fad530adb80e19b4dedfad7290487fdb1fc5fcf77b1df69cf74f9ada9c0ff303cd93984bb6829fab1c93402cb83b94d74ccea316fb0a54a3992da499bcc090b0106a0e302370b165a2adc84e5ae75a269d864547479a7243d77ae4ef063147bfb859aa378b253bf7a2cc5959de84471f4f27937f81e64ec9c16b21ec8226717cded1e3e8839b6500e805a5dd5ac65c5d13aba84f09bc471cbe0ec6b67eadbd53b54c1d598254b56a31f1567baf6c12fac9e20d79e19ef2d9a7d0abc2f5bfc5831bb42c6ed30bc8bbe0a446ec4cf6fa6dc1b7a717cf734b257278a3ad1cf1e715769b1b4ec887db09e03fcc6c991f164b1f893e77f29978523f",
            bitlen: 2047
        });
    }

    function getV() external pure returns (BigNumber[] memory) {
        BigNumber[] memory v = new BigNumber[](20);

        v[0] = BigNumber({
            val: hex"a7eb9d9cbff62441755b7ee23948aefa09189714291903fb653f53df530751028d88f37de6a5ad2387d963a3e0b4c3c02780cc46969802f2b0432ff8061a09085b21e2948c90a02c284100b1dcde05a2d02e3cdf8bc89969a0dd46fc358ccfa58a3cae3ffd147071c18a9fafe4125e264febc6746465ba4b21d56cf1c69f5c673943207b63b69df6870e4136c8770a3f871522d4fe2372907fa057f937f3249188630b1dd887ef89f878a7454335088e665b91749282d2dc06774309c6fe068ea3688fd51265a64d88c987db21d9708f685d26b9b2da347469997d2bf9a148b78d50257388f8d4904b4aca64cacebe3724a4ea9f158957d0c5e5f40b052be62e",
            bitlen: 2048
        });

        v[1] = BigNumber({
            val: hex"34c66580116580667ffb88c11afd58dee310d00ccee1374d28c77415f890bd42fc9cccc0da8cb082ebbb39d4248bb8d297ce977c2fbc42036ad8a23da33be74dec433b12e3f7bc93a37670dfe3fc13690fcdf4b4b1f33dcde1cc99a9fcb0fd1cc2998866df7e20517e568fa42652bea6258484dd9a9fa591097392e4b4320a11479ac06f6e5baae951d797fcec0432caa348a146c9ffefb152607050412dd44186ef47c26df5d967c338bd51b2db3ebf23e3378467f59b45230ffa79f4af676af6bf181da5cca166d8b0ef7a144e568bd20637e7a14d6664c690603ebb48a51f35297e49592b272621bea1cb789c41bc95c5e3ae1721b8b104501332761edcf9",
            bitlen: 2046
        });

        v[2] = BigNumber({
            val: hex"04435febff13e7ece600ba20a61279b512497f77288ca350fc2d16c5e7bbf358b40259a3c53fffeaccd834d7736b72412bed0329d9277c7fb917b42d67ab2e0175b05dbaaaa267c813367deaeb1e348af5a1ed8581cb0b3cb540864debec8a8bac2771ed1a54be5c689767e897ee3d60099a5c6ce6dfb622b2f2fa9f9c07cc6d3f1ce377dfaec40c16a543067fb4c991a9646023e855394216fc8ea48cc4e170da35e7de5fbfea6457161312273e55131a007805b1bd179139f5a8740c6341dceac1db2abac8a6cec9791e6bf053ef2fc6171799e484333643b99d0e036687c7fdf2a8a05b55f5cb66290cd763ebe567d1ddf5b554e088c8e3c100a764839dc4",
            bitlen: 2043
        });

        v[3] = BigNumber({
            val: hex"b0c7e9718e02f72ba821cb231fa48d7d2a8df9bb333035130cbc55a05c7bde668ce44538a45408228380f2efcf0a0dda933b9a164f3e3177db3b759fa04fa20d6c3e31afe007d12944229d16958fbc9a01bc1d35191310d3c16766ce002e97961402035d4343aaa8c10b0c42acba5075b2e107463981c08c16d293d28e30023c4d05fb1ab825f2c6a610eecd2d1c772b4afd6c8257ffa7e2c0724983fdbf297ce1d457c5a98f727db8737df66369af9f3a3a194ce101e6bee6e3da3d31cb8f72877067fb64250621ba3d18475c79e92f050aedf652957ba4f160ae1e747adb278ec746a168972026f9479764d65446d69bd8b5d9f8cdfe900b80da15d871cfda",
            bitlen: 2048
        });

        v[4] = BigNumber({
            val: hex"2a67c9cb6734343353f400241a6d0414dd72e685dfdb3774e2a7fb4120e564aeb141fc8f705d7d10a9df98547baab2650f0e33b2b0631fd3bcb9416b82babeed52d006034984757f0430181d593ee73680bc23d15ec343c93af632c08e71b182158fbdc2cb3234c9e3bf0cd4410b804cd9bcf8d6f86de16700d7753a345e83fb012d8805e850b1371235925279fa7611930cd7934377dc41fb42a708b0d006382234a695b2eaaeb52cc05df9fcf909f2a7541bfcb46a68896a1e16992df22c0a10080365c3f53fc538c3fbbf8baf153688d56556e77e912df0d1b311887d3560e569af0af12fa4398befd02ef9c126fad477669bb079f311741a0271e1a78e94",
            bitlen: 2046
        });

        v[5] = BigNumber({
            val: hex"7bab8efa0664b53c0c21b4244ed4a1cd10b2aadc5ecfcadb25f0ef769e575f03b3a46b82cc16002f82a1f426df3c9ded361eacc8eac2371db3e37ff1e3ffa625f3db91bb90807b0fdda24f676f83bc65c544c7db14eebfed9edf68eacaa15ccdd06ca1993fbb7bea5ba95b00b510f3be57bc9c6a2b56151c70060f4d3f0f994e70751d160cfbbd572b5f0248984347fe43d48c74dadbeb2f6b83b6f686b8c5d2292c069edae905ae6ee99dec70b4d4cdb18164e54d4dba1ce70e6fb1dd03c72c21ae35a4fc2dcdcad84f845d61114e33f05931e50bf0a8d5ffb2eff202ef789aa7bc09c2b41de1aa337c6612d5806f13917cb5490933983e3b104b4f02223039",
            bitlen: 2047
        });

        v[6] = BigNumber({
            val: hex"1c4fa2125bc61b4e0b906f39f5967cb85d6035319e05de3c7110e92551c6bcadcfe680b044a7757ed65432345bac58152d99a073985de3099ffd276d0647edbc191be1a8556394396fdbe4bff9ae8d0981d90d5cab6826f1e87f800c5ba45bbeb3c71835018d1aaa7a53e11ef7158eb3a95db6e3f4c058c0c09e7c950e64880c5d2e6643f852d7d9d010de7d0326859fbe9f9288ab128178fb0eec443a1cd521fa534f3afe92965af328229b0653320176f56b19db4c3d97a9f9cd8768faf1195bfd635679d806230132952ecdc0f843279c1a25ff9e1960bc0d1c5620665d34d98f4fa9bc801fcee1b8bf1ebe4ac5f712ca082c28cdbe4ab6a2dcef4f7ebc2b",
            bitlen: 2045
        });

        v[7] = BigNumber({
            val: hex"77c7834e897c42e255e6edb48b21d814f1fba4ee88b8dbb8ccb5b6a7d422eaf1302fe264078505b0625baf3f67685d0ebe21758480ac55d407486863b700d5331dd23d3eb89cf8c2ba148e2db4d107b5d4a025da87ec55b061185f730e148723d20593c00a178ccaff5dec28d553522ec6529294da8c447963a8a370714cfe612634ae7e66e562011ff719db4ce2ad7feef66761daf291f93ef0bbb21bb1560a5401cae4955b0a5dab2ca197de584fbce45fda338b153de778c0192f70674c20077bc151431cb915a6dfd23c366bc3be097af0ba01f67689821ecc7913c27ba03f06f608472f0a17e06fed590d6ce83ab9777ec539a4989d77de2f700285d836",
            bitlen: 2047
        });

        v[8] = BigNumber({
            val: hex"18fb8cc6750696a02dac33812f47cda227b33074b43897a3b3286b63727ef7b0fcabab77bf6600488ab5f90f59ef7d9015b491e02ef33cdd5c2289c5b3470e348f1cde9f08ce7beb1159e7c0150f8016b3df2af65010d8f0c8e435bea4a2a5431bec464106863b3811bdb2ff274eac3fe27c531714d4a3cfdb2c8ec0f3610cca62c86b42b69417ef4a05b7b13bb686aac6b18003d903dd5870a59b0aea86d26d2ba3b95150cd044fa98b8b2480407b4dee0456cbb9213ac2c55014e8a8423aadee97a9229b3a52e5764d3c2218ed2741c0418e9db3448723f1c5e39a645b3f31b25d8b6d1f29401cfe9cb317f5271c8d30b8f560b90c0e277dba86539eceac6a",
            bitlen: 2045
        });

        v[9] = BigNumber({
            val: hex"42e90092fd555ba2478d90ed4dd225244e13cfc0fd5d0f52413299d5fed4ce2c8d161f31a59f3abfe5ffaf0fa0a5026e5b45e0e432837d40e1bab2b65bf40daa1930bf1ba7ab37244dbf3e7ae143f6694b5db788eeb50032272bba4d32fb6f7c1cdb85836a6eb5d7e79a038858f1e8586e17bd4ff58f148bd563f6589e39938a8ffb80e84df4d842ba68d5f21f9905bbc2d090b8c885227d63be5ede94bc858d7593ce691b91838d68a492e451d9f7d146d36c2b5a4d655133484f2eabcbc6a3765e3d4a67be158613185b3386e6896a46081210ab851d1ca44e596386af4be3c25d3c3d5bf1692f49971688e061173f31d520e56b4aaaaa46ef9ae357cd894d",
            bitlen: 2047
        });

        v[10] = BigNumber({
            val: hex"afc297a7c08794b1f3746ea12d6dfcd19df5ef38232fe3c6ecd4be81ea5aec1dc6ec432260e904e17f39628abeda5a36bcd515aa66897cc61f14f3cdd76b13fcb35776fe0f53521b6e974851aa9fa65e8309180bdd7e04583915924b00443c5121512b275f641446a4fecd07f51324cdc10eae3ec5806c96c62de815a20718cecc1b713079ce1d7f41559be6bb478a61dc59e28c28accb9328969d9760de696f151e5a604bef5f32cf178843969a16ef1ea0f9fdf1ea413896f8c1771ededd454c3cc3cf180adf2d1422ab66a3f7f6aee47c17eb3b55ccfeced17275e3b4a45da1f364da03ed8b580523987dcc46cbbc003507e356c91802dbaf41b01dac6f74",
            bitlen: 2048
        });

        v[11] = BigNumber({
            val: hex"774110e48350ed934de59816069fed16c0c6dc0da945053d45b5e103017f132d8fcdf02335d250b78f8007cb05487df3a90d939bb7d82ccc6aab9a0351a04cf00b57c9a1931ebb0911e45e06ba58d922bcac7cc86b4653316f892b205059cb508348e4f5b1b0eb72220283c1918dfe0032c71274574ee2c90e185cf47781d857443d82b9b5e23179f6df36863869d908ae554d7a936237c0701882d4c6da92285d1a91ea6906abb028ede77ef2809060b1b00d354e0a2a35ab5383ed358836360eb04939996c385bcb574faae47cf07dce95af020476993106d4fb35f4ba86664cd007559d214c831aefa5f7355f4727225d8ecbc093eab6334c810b632ba87b",
            bitlen: 2047
        });

        v[12] = BigNumber({
            val: hex"8abaf26b9fa465c482486454298ad7074bc46a7801d2f1d1b4d285da3ce4c184b7864b3698f22f071dde4b9e26d174c2900de2b84c215fcca84039f368642ffd222150f3eca20f419bc61d38873f036a2c4d9b96e16965b80c08177e276c94f5842d1bcebe4c7a86d90bfa0f719f447997ab0c8a55cf828edee4b5e2a826bfbaa3da18984f1e87a81b2ea07a3542e6697f893c292db87b6d339174689bed1fd284621c7fab5eba61afff2d8a170b0df9a650156ab90db3c2a44a721ca5fd739d3b04135b1abb47903e95bee05255e15b40d56f2373207d0b3ee769972d7c4ac07fe31bae37147e4bcd6d8c08b7172e07876f25c1ee89f1957539cb6c6a391125",
            bitlen: 2048
        });

        v[13] = BigNumber({
            val: hex"6dca9ef2c88ae297f1202fd1c52618ad0b2158b4c9fe3a512999f1e897aee5a3397c8e253b0666375a7274726be67f4335bc63fd65ef4c8148d034f7ae0c03516e2e51834addc4bf0172ebd1e599a842eb3292d1723192188aac7c53a9f18eaa5c7d277828985a4ce788d9e2ae9b55227c453b2daafe2d3b51008b4c132336551b705e339660878d8d3f30c69c4c75c71e7ff1ebec594369942757257a5562e45207534b80af110ed6f61dc7761836f97bb553000136003a4a73b421b2c48c5e316d589ef6ebc48c842b5f89b3845807e3aac0a57c70df6a105de1518e6e02dabcf9f100d12fc4100a21909592c40bdcf412f35b8c45b9025b8f25491562b702",
            bitlen: 2047
        });

        v[14] = BigNumber({
            val: hex"8e303284f86d2bb3d36d88c40bde2b022262a1da1e97498d6dcca75faa7b5535e3babb2cbe6002891587c7e55032534593b29be03fa03ac429166d3bd9a3dfac447071fa46a18c00eeb09de6ccba34a102fd40f0c133b38ff41dbbb9d8eeaba18317ece77d8d091b54c947fc15216d0214ea136617a23770b74cfe5dbc3c98f4df6a52efb15390037649e2f9bbf238736cb291f15a991c2010c241d5aa7c60f89f04867051d1c2622c4f2386e7d8997a481f2a843071e6748dc0f1dd59a2d62f30584b8489cbcd95fb5cd6b5bae34b1d8f63721b7e8c9c64c8bf31c60a2d1ef34aa0a0ad74c6d132d1dced357c9834fbd6ec27d7e39535242b5f2ad030fce13d",
            bitlen: 2048
        });

        v[15] = BigNumber({
            val: hex"c434e04a80dfbd08cf2cd78425d2e9bb840786c51bf4ec46fdf69c4ecca41585f4287941245f9d4bbab0210af7da76bdb357fa707e6319609b2fc82d1efa75cc7cfdb05e8ce5da4af962c4d5453bc51a71168382ec6f5e1c94e2bcd1343e24d88b277fa85e9343d8ee9ca1e44fa48cf87ef2e3c17a1b3792ba64fb67b0c3037d7ef075a77c6abffc5bd1927561cea43b353b297a67ca67e393539ac6654dd0752b10922a0ec53398a084e60996d61fde5dd24cd3ddf426179c2bcdbda9c61d58c3c3dda58f27b0ae0f126967872bbe2f37cf04093bb96d6ef332eee36e6a169232cb9288d21de7ee00eea925b912d87cc44d304d13646355f69a241b7d6ce204",
            bitlen: 2048
        });

        v[16] = BigNumber({
            val: hex"095cf7b78dd3003656f7e2fcadad48c9c8604ee37c82296aef4a8951064acd911e66d135393eb4f9ae84902f78b3d1c7a2edb69aaf5aaa1e38cd56170ffcc4cdb3d972e920592199c60d8ba112507fdbaa960bf95ef99efd1e61296111875a9f2897f897e556b959dc9cba557cbac204eff5d8d5d35b1d02f1284f42cb96a3e73305e330b50d7334e5000450726652abbf68e75e8228d2d5197225d924689eea9cf231854bdad9c5e27af88cc3d63681297f783179678732b1f437dd047f6ea96f4310e1b44ff637d736f46b6877901e4b94c57ed4ebbd116a691e8d2c2b54e112297ee2923108b4bd6367c320af0627b1d2decd4af567a8dff73b026e7105fc",
            bitlen: 2044
        });

        v[17] = BigNumber({
            val: hex"481e7632eeec2d69a7a3e932e1324db3f651bffb16268f257039a4615df790a403486cd521c8b947b0cce22a89a2b3fe366d9ed3ea8ed142337f62864d360b39d523ad33916bdd0f733d9e447c5d92568430ceb5dea4991fdd34ab4763fccd2a004da1c5f7af2d531527f8d0ce8bfa3fef6c52cace4a23eba1d8eac3447b9558b72c410afd1877e4b13b74b0ef2e640bfa2f6a52e56fcd80b09b54cef5248c4d61fe39ab0f1e6c1196c09b2fb08d3d4412314a06c78e04b0a565eae055f9612d59862428fc79513221e7b395e0cc52edba3a97feee0d3032aaf913d84ca4b2937ad353754ac6b988c3742dca1fe12a5c8dfbc5248cc71f46514e44b40b03d9d2",
            bitlen: 2047
        });

        v[18] = BigNumber({
            val: hex"33addfb92ff82bf7637cf8e1d54e0996b5f4f94157e6821c886ef4346e18b782279486f012a5c685abbdb2939d0c6d39944af89172eba4c53b9eda76cd7e17116ecac2e5162b13d10e051e65a6e780bef7d9d55549cc871a040686b9b1e560e3406c920e77328ceca6d23755f8c4e92b0f4a7c3116d5051ee49e9dd4f2e7233111217e554d3b864df118c8325bb6df126fce16620a5a353b6492f5c4ed4e882002a81434bb5d02d3ac260a318013df2584cd1ac742855bb761a3f1db28a5204746887cdd115390cd5de4e68aedebd43ae93c6db395c339911e0e4690f9bc1479df81aa239dce1f6cda3c1b3e195e29f490e175425838f2050d5f55e2908fbd95",
            bitlen: 2046
        });

        v[19] = BigNumber({
            val: hex"0c94d9c167097eab8663a900e62d0d7aa28b2cd85d2204702f0411844fdff49fae9eadf80e4d6739c86fd99b3e8750bc25866efcf6f681f51bfb59c2a346e7a193a333281211f88efb8c2d18aabbcb1c99c83c9ca78ba6cd72f5bed5c345a9047e1c68f41cb40ac85d70d4165c665b1e30cd41afed7806933765ade4f97d4b41902566f437a98e769259cfe9835d8f938e7583e59b2c7aa685adc3f19a5953615c144394a9b7268ea91cd9e1791f988baac0f00ee4921645b22a3d17abb298eb4c71ac32633beac7553f40dbb1ff54d2adff0c018dff510f6c3f9c416836d23ca8890c3867b60b4c17f052db58ef0c328fc47f116872bb7a0d44d618c774bc12",
            bitlen: 2044
        });

        return v;
    }
}
