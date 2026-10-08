Config = {}

Config.Debug = false
Config.AdminGroups = { 'admin', 'superadmin' }
Config.OpenCommand = 'orgtablet'
Config.AdminCommand = 'orgcreate'
Config.AdminDeleteCommand = 'orgdelete'
Config.InviteTimeout = 60 * 60
Config.TaskDistance = 3.0
Config.MaxNotesLength = 2000
Config.MaxOrgNameLength = 32
Config.MaxShortLength = 8
Config.CurrencyAccount = 'bank'
Config.BankingResource = 'p_banking'
Config.Tablet = {
    animDict = 'amb@world_human_seat_wall_tablet@female@base',
    animClip = 'base',
    prop = 'prop_cs_tablet',
    bone = 57005,
    offset = vec3(0.17, 0.10, -0.13),
    rotation = vec3(20.0, 180.0, 180.0)
}
Config.CompanyUsesESXJob = true

-- Firmy działają na ESX jobach. Rangi i uprawnienia są pobierane z tej konfiguracji.
-- job musi istnieć w ESX.
Config.Companies = {
    ['mechanic'] = {
        label = 'Los Santos Customs',
        defaultGrade = 0,
        fireJob = 'unemployed',
        fireGrade = 0,
        grades = {
            [0] = {
                name = 'Pracownik',
                permissions = {
                    ['tablet.view'] = true,
                    ['members.view'] = true,
                    ['ranks.view'] = true,
                    ['tasks.view'] = true,
                    ['notes.view'] = true,
                    ['notes.write'] = true,
                    ['shop.view'] = true,
                    ['shop.buy'] = true,
                    ['bank.view'] = true,
                }
            },
            [1] = {
                name = 'Kierownik',
                permissions = {
                    ['tablet.view'] = true,
                    ['members.view'] = true,
                    ['members.hire'] = true,
                    ['members.fire'] = true,
                    ['members.rank'] = true,
                    ['ranks.view'] = true,
                    ['tasks.view'] = true,
                    ['tasks.start'] = true,
                    ['notes.view'] = true,
                    ['notes.write'] = true,
                    ['notes.org'] = true,
                    ['notes.manage'] = true,
                    ['shop.view'] = true,
                    ['shop.buy'] = true,
                    ['bank.view'] = true,
                    ['bank.deposit'] = true,
                    ['bank.withdraw'] = true,
                    ['activity.view'] = true,
                }
            },
            [2] = {
                name = 'Szef',
                permissions = { ['*'] = true }
            }
        }
    },

    -- Eclipse Club (zasob mrp-eclipse). Grady odpowiadaja jobowi ESX "eclipse":
    -- 0 pracownik, 1 ochrona, 2 kierownik, 3 szef.
    ['eclipse'] = {
        label = 'Eclipse Club',
        defaultGrade = 0,
        fireJob = 'unemployed',
        fireGrade = 0,
        grades = {
            [0] = {
                name = 'Pracownik',
                permissions = {
                    ['tablet.view'] = true,
                    ['members.view'] = true,
                    ['ranks.view'] = true,
                    ['tasks.view'] = true,
                    ['notes.view'] = true,
                    ['notes.write'] = true,
                    ['shop.view'] = true,
                    ['bank.view'] = true,
                }
            },
            [1] = {
                name = 'Ochrona',
                permissions = {
                    ['tablet.view'] = true,
                    ['members.view'] = true,
                    ['ranks.view'] = true,
                    ['tasks.view'] = true,
                    ['notes.view'] = true,
                    ['notes.write'] = true,
                    ['shop.view'] = true,
                    ['bank.view'] = true,
                }
            },
            [2] = {
                name = 'Kierownik',
                permissions = {
                    ['tablet.view'] = true,
                    ['members.view'] = true,
                    ['members.hire'] = true,
                    ['members.fire'] = true,
                    ['members.rank'] = true,
                    ['ranks.view'] = true,
                    ['tasks.view'] = true,
                    ['notes.view'] = true,
                    ['notes.write'] = true,
                    ['notes.org'] = true,
                    ['notes.manage'] = true,
                    ['shop.view'] = true,
                    ['bank.view'] = true,
                    ['bank.deposit'] = true,
                    ['activity.view'] = true,
                }
            },
            [3] = {
                name = 'Szef',
                permissions = { ['*'] = true }
            }
        }
    }
}
Config.RequireOnlineTargetForCreate = true
Config.TaranItem = 'taran'

-- Podłącz tutaj swój system ubrań, np.:
-- Config.ClothingExport = function() exports['twoj-clothes']:openWardrobe() end
Config.ClothingExport = nil
Config.TaranDuration = 7000
Config.TaranDistance = 2.0
Config.TaranRequiredPolice = 0
Config.Logs = {
    enabled = false,
    webhook = ''
}

Config.Messages = {
    noAccess = 'Nie masz uprawnień do tej funkcji.',
    saved = 'Zapisano zmiany.',
    notFound = 'Nie znaleziono danych.'
}
