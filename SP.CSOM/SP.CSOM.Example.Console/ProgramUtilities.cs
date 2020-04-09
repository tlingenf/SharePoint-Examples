using System;
using System.Linq;

/*
 * ##########################################################################################################
# Disclaimer
# The sample scripts are not supported under any Microsoft standard support program or service.
#
# The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability or of fitness
# for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and
# documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the
# creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without
# limitation, damages for loss of business profits, business interruption, loss of business information,
# or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages.
##########################################################################################################
*/

namespace SPExamples.Console
{
    static class ProgramUtilities
    {
        internal static string GetInput(string label, bool isPassword, ConsoleColor defaultForeground)
        {
            System.Console.ForegroundColor = ConsoleColor.Green;
            System.Console.WriteLine("{0} : ", label);
            System.Console.ForegroundColor = defaultForeground;

            string value = "";

            for (ConsoleKeyInfo keyInfo = System.Console.ReadKey(true); keyInfo.Key != ConsoleKey.Enter; keyInfo = System.Console.ReadKey(true))
            {
                if (keyInfo.Key == ConsoleKey.Backspace)
                {
                    if (value.Length > 0)
                    {
                        value = value.Remove(value.Length - 1);
                        System.Console.SetCursorPosition(System.Console.CursorLeft - 1, System.Console.CursorTop);
                        System.Console.Write(" ");
                        System.Console.SetCursorPosition(System.Console.CursorLeft - 1, System.Console.CursorTop);
                    }
                }
                else if (keyInfo.Key != ConsoleKey.Enter)
                {
                    if (isPassword)
                    {
                        System.Console.Write("*");
                    }
                    else
                    {
                        System.Console.Write(keyInfo.KeyChar);
                    }
                    value += keyInfo.KeyChar;

                }

            }
            System.Console.WriteLine("");

            return value;
        }

        internal static string GenerateRandomeString()
        {
            Random random = new Random();
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            return new string(Enumerable.Repeat(chars, 6)
              .Select(s => s[random.Next(s.Length)]).ToArray());
        }
    }
}
