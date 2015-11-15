using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace MjaiForms
{
    class Protocol
    {

        public static object none()
        {
            return new { type = "none" };
        }

        public static object join(string name, string room)
        {
            return new { type = "join", name = name, room = room };
        }

        public static object hora(int actor, int target, int pai)
        {
            return new { type = "hora", actor = actor, target = target, pai = Pai.dump(pai) };
        }

        public static object dahai(int actor, int pai, bool tsumogiri)
        {
            return new { type = "dahai", actor = actor, pai = Pai.dump(pai), tsumogiri = tsumogiri };
        }

        public static object reach(int actor)
        {
            return new { type = "reach", actor = actor };
        }

        public static object pon(int actor, int target, int pai, List<int> consumed) {
            return naki("pon", actor, target, pai, consumed);
        }

        public static object daiminkan(int actor, int target, int pai, List<int> consumed)
        {
            return naki("daiminkan", actor, target, pai, consumed);
        }
        public static object ankan(int actor, List<int> consumed)
        {
            return new { type = "ankan", actor = actor, consumed = consumed.Select(Pai.dump).ToList() };
        }
        public static object kakan(int actor, int pai, List<int> consumed)
        {
            return new { type = "kakan", actor = actor, pai = Pai.dump(pai), consumed = consumed.Select(Pai.dump).ToList() };
        }

        public static object chi(int actor, int target, int pai, List<int> consumed)
        {
            return naki("chi", actor, target, pai, consumed);
        }

        static object naki(string type, int actor, int target, int pai, List<int> consumed)
        {
            consumed.Sort();
            return new { type = type, actor = actor, target = target, pai = Pai.dump(pai), consumed = consumed.Select(Pai.dump).ToList() };
        }

        public static object kyushukyuhai(int actor)
        {
            return new { type = "ryukyoku", reason = "kyushukyuhai", actor = actor };
        }
        
    }
}
