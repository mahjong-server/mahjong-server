using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.IO;

namespace MjaiForms
{

    class Algorithm
    {

        private static Dictionary<int, List<Tuple<int, int>>> SHANTEN_TBL;

        public static void init()
        {
            SHANTEN_TBL = new Dictionary<int, List<Tuple<int, int>>>();

            foreach (string line in File.ReadAllLines("../../shanten.txt").Skip(1))
            {
                int[] tmp = line.Split('\t').Select(Int32.Parse).ToArray<int>();

                var key = tmp[0];
                var v = tmp[1];

                SHANTEN_TBL[key] = new List<Tuple<int, int>>(){ 
                    Tuple.Create(v/1000%10, v/100%10), 
                    Tuple.Create(v/10%10, v%10)
                };
            }
        }

        static int calcHash(int[] t)
        {
            return t.Aggregate(0, ((acc, x) => acc * 10 + x));
        }

        static void removeKoritsu(int[] t)
        {
            for (int i = 0; i < 9; i++)
            {
                if ((i - 2 < 0 || t[i - 2] == 0) &&
                   (i - 1 < 0 || t[i - 1] == 0) &&
                   (t[i] == 1) &&
                   (i + 1 > 8 || t[i + 1] == 0) &&
                   (i + 2 > 8 || t[i + 2] == 0))
                {
                    t[i] = 0;
                }
            }
        }

        static int pickMenta(int[] t, int needMentsu)
        {
            var mts = new List<List<Tuple<int, int>>>();
            for(int i = 0; i < 3; i++) {
                int[] tt = t.Skip(i*9).Take(9).ToArray<int>();
                removeKoritsu(tt);
                var h = calcHash(tt);
                mts.Add((h == 0) ? new List<Tuple<int, int>>() { Tuple.Create(0, 0), Tuple.Create(0, 0) } : SHANTEN_TBL[h]);
            }

            var mJihai = t.Skip(27).Take(7).Count(_ => _ >= 3);
            var tJihai = t.Skip(27).Take(7).Count(_ => _ == 2);

            int ans = Int32.MaxValue;

            for (int i = 0; i < (1 << 3); i++)
            {
                var mts_ = Enumerable.Range(0, 3).Select(j => mts[j][i >> j & 1]);
                var m = mts_.Select(_ => _.Item1).Sum() + mJihai;
                var a = Math.Min(mts_.Select(_ => _.Item2).Sum() + tJihai, needMentsu - m);
                ans = Math.Min(ans, 8 - 2 * m - a);
            }
            return ans;
        }

        static int normalShanten(int[] t, int needMentsu)
        {
            int ans = 10;
            for (int i = 0; i < 34; i++)
            {
                if (t[i] >= 2)
                {
                    t[i] -= 2;
                    ans = Math.Min(ans, pickMenta(t, needMentsu) - 1);
                    t[i] += 2;
                }
            }
            return Math.Min(ans, pickMenta(t, needMentsu)) - (4 - needMentsu) * 2;
        }

        static int kokushiShanten(int[] t)
        {
            var yaochu = new List<int>() { 0, 8, 9, 17, 18, 26 }.Concat(Enumerable.Range(27, 7));
            var kind = yaochu.Count(_ => t[_] >= 1);
            return 13 - (kind + (yaochu.Any(_ => t[_] >= 2) ? 1 : 0));
        }

        static int chitoiShanten(int[] t)
        {
            var toitsu = t.Count(_ => _ >= 2);
            var kind = t.Count(_ => _ >= 1);
            return 6 - toitsu + Math.Max(7 - kind, 0);
        }

        public static int shanten(IEnumerable<int> tehai) {
            int[] t = new int[34];
            for (int i = 0; i < 34; i++) t[i] = 0;
            foreach(int pai in tehai) {
                if (pai < 0 || pai > 37 || pai == 30) continue;
                int suit = pai / 10;
                int num = pai % 10;
                if(num == 0) num = 5;
                t[suit * 9 + num - 1]++;
            }
            int needMentsu = tehai.Count() / 3;
            if (needMentsu == 4)
            {
                var tmp = new List<int>() { normalShanten(t, needMentsu), kokushiShanten(t), chitoiShanten(t) };
                return tmp.Min();
            }
            else
                return normalShanten(t, needMentsu);
        }

        public static bool canChi(IEnumerable<int> tehai, int pai)
        {
            if (pai / 10 == 3) return false;
            if (pai % 10 == 0) pai += 5;

            tehai = tehai.Select(_ => (_ % 10 == 0) ? _ + 5 : _);

            int num = pai % 10;

            if (num >= 3 && tehai.Any(_ => _ == pai - 2) && tehai.Any(_ => _ == pai - 1)) return true;
            if (num >= 2 && num <= 8 && tehai.Any(_ => _ == pai - 1) && tehai.Any(_ => _ == pai + 1)) return true;
            if (num <= 7 && tehai.Any(_ => _ == pai + 1) && tehai.Any(_ => _ == pai + 2)) return true;
            return false;
        }

        public static bool canPon(IEnumerable<int> tehai, int pai)
        {
            if (pai % 10 == 0) pai += 5;
            tehai = tehai.Select(_ => (_ % 10 == 0) ? _ + 5 : _);
            return tehai.Count(_ => _ == pai) >= 2;
        }

        public static bool canKan(IEnumerable<int> tehai, int pai)
        {
            if (pai % 10 == 0) pai += 5;
            tehai = tehai.Select(_ => (_ % 10 == 0) ? _ + 5 : _);
            return tehai.Count(_ => _ == pai) >= 3;
        }
    }
}
