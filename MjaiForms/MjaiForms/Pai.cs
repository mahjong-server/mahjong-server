using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace MjaiForms
{
    class Pai
    {

        public static string dump(int pai)
        {
            StringBuilder sb = new StringBuilder();
            int rem = pai % 10;
            if (pai >= 30) sb.Append("?ESWNPFC"[rem]);
            else if (rem == 0)
            {
                sb.Append(5);
                sb.Append("mps"[pai / 10]);
                sb.Append("r");
            }
            else
            {
                sb.Append(pai % 10);
                sb.Append("mps"[pai / 10]);
            }
            return sb.ToString();
        }
    }
}
